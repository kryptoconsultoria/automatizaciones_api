*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           String
Resource          funciones/leer_pdf.robot
Resource          funciones/descargar_onedrive.robot

*** Variables ***
# ${config_file}    ../config.yaml
# ${config_file_pdf}    ../config_pdf.yaml
${REGEX_EXP}    \\$\\d{1,3}(?:,\\d{3})*
${REGEX_EXP_NIT}  \\b\\d{2}\\s\\d{5,}\\b

# *** Tasks ***
# LLenar PDF 2276
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}=    Read File    ${config_file}
#     ${yaml_content_pdf}=    Read File    ${config_file_pdf}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
#     2276    ${config}    ${config_pdf}

*** Keywords ***
2276
    [Documentation]    Lee archivos PDF, extrae información utilizando expresiones regulares y clasifica los datos en la base de datos correspondiente
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${pdf_2276}    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   pdf_2276
            ${pdf_2276_2}    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   pdf_2276_2
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            #==================================================================================
            # Iterar sobre cada ruta en rutas_locales
            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${carpeta_2276}    Replace String    ${CURDIR}/../${pdf_2276["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${pdf_2276["ruta_nube"]}    CLIENTE   ${cliente}

            # Crear carpeta si existe 
            ${existe}    Run Keyword And Return Status    Directory Should Exist    ${carpeta_2276}
            IF    not ${existe}
                Create Directory    ${carpeta_2276}
            END
            
            #Borrar archivos de cada carpeta
            OperatingSystem.Remove Files    ${carpeta_2276}*

            #Enlistar archivo de sharepoint
            ${estado}  ${archivos}    Listar archivos    refresh_token=${token_refresco}     secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}   nombre_del_sitio=${sharepoint['nombre_sitio']}    ruta_carpeta=${ruta_nube}    id_cliente=${sharepoint['id_cliente']}
            IF    '${estado}' == 'No encontrado'
                ${completado}=    Set Variable    ${True}
                RETURN    ${completado}
            END

            FOR    ${archivo}  IN   @{archivos}
                #Descargar archivo de sharepoint
                ${archivo}    Convert To String    item=${archivo}
                ${archivo}    Replace String    search_for=File:    string=${archivo}    replace_with=${empty}
                ${archivo}    Strip String    string=${archivo}
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${carpeta_2276}
                IF  '${estado_descarga}' == 'Fallido'
                  ${completado}=    Set Variable    ${False}
                  RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                  CONTINUE
                END
            END
            #==================================================================================
            ${archivos}=    OperatingSystem.List Files In Directory    ${carpeta_2276}

            FOR    ${file}    IN    @{archivos}
                ${archivo}    Set Variable         ${carpeta_2276}${file}

                #Obtener cantidad de páginas
                ${numero_paginas}     Obtener Numero Paginas    ${archivo}

                FOR    ${i}    IN RANGE    0    ${numero_paginas}
                    # Leer el contenido del PDF
                    ${informacion}    Leer PDF Plumber     ${archivo}    ${i}

                    # Obtener tipo de documento y numero de documento
                    ${matches}    Get Regexp Matches    ${informacion}     \\b\\d{2}\\s\\d{5,}\\b
                    ${documento_y_tipo}    Set Variable    ${matches}[0]
                    ${documento_y_tipo_lista}    Split String    string=${documento_y_tipo}    separator=${SPACE}
                    ${tipo_documento}    Set Variable    ${documento_y_tipo_lista}[0]
                    ${documento}    Set Variable    ${documento_y_tipo_lista}[1]
                    
                    # Iterar sobre cada clave en la configuración de la ruta
                    FOR    ${key}    IN    @{pdf_2276.keys()}
                        ${es_regex}=    Evaluate    'ruta' in '''${key}'''
                        ${es_regex_2}=    Evaluate    'documento' in '''${key}'''
                        IF    not ${es_regex} and not ${es_regex_2}
                            ${matches}    Get Regexp Matches    ${informacion}     ${REGEX_EXP}
                            ${matches_ancho}    Get Length     ${matches}       
                            IF     ${matches_ancho} != 0
                                ${valor_extraido}    Set Variable    ${matches}[${pdf_2276}[${key}]]
                                ${valor_extraido}    Replace String      ${valor_extraido}     $    ${EMPTY}
                                ${valor_extraido}    Replace String      ${valor_extraido}     ,    ${EMPTY}

                                ${sql}    Catenate     
                                ...    UPDATE formato_2276 SET ${key}='${valor_extraido}',
                                ...    TipoDoc='${tipo_documento}' WHERE NumId=${documento} AND Usuario='${usuario}'
                                Execute Sql String   ${sql}
                            ELSE
                                # Primer reemplazo: escapa '('
                                ${regex_texto}=    Replace String    string=${pdf_2276_2}[${key}]    search_for=(        replace_with=\\(

                                # Segundo reemplazo: escapa ')'
                                ${regex_texto}=    Replace String    string=${regex_texto}    search_for=)        replace_with=\\)

                                ${matches}    Get Regexp Matches    ${informacion}     pattern=${regex_texto}.*?(\\d[\\d\\.]*)(?=\\r?\\n|$)
                                ${valor_extraido}   Split String    string=${matches}[0]    separator=${SPACE}

                                ${valor_final}    Replace String      ${valor_extraido}[-1]     $    ${EMPTY}
                                ${valor_final}    Replace String      ${valor_final}     .    ${EMPTY}

                                ${sql}    Catenate    
                                ...    UPDATE formato_2276 SET ${key}='${valor_final}',
                                ...    TipoDoc='${tipo_documento}' WHERE NumId=${documento} AND Usuario='${usuario}'
                                Execute Sql String   ${sql}
                            END
                        END
                    END

                    ${sql}    Catenate
                    ...    UPDATE formato_2276 SET IngresosBrutos=CAST(Salarios AS SIGNED)+CAST(EmolEcles AS SIGNED)+CAST(BonosServ AS SIGNED)
                    ...    +CAST(ExcesoAlim AS SIGNED)+CAST(Honorarios AS SIGNED)+CAST(Servicios AS SIGNED)
                    ...    +CAST(Comisiones AS SIGNED)+CAST(Prestaciones AS SIGNED)+CAST(Viaticos AS SIGNED)
                    ...    +CAST(GastosRep AS SIGNED)+CAST(CompTrabajo AS SIGNED)+CAST(ApoyoEcon AS SIGNED)+CAST(otrosPagos AS SIGNED)
                    ...    +CAST(CesIntereses AS SIGNED)+CAST(CesFondo AS SIGNED)+CAST(AuxCes AS SIGNED)+CAST(Pensiones AS SIGNED)
                    ...    WHERE NumId=${documento} AND Usuario='${usuario}'
                    Log    ${sql}    level=DEBUG
                    Execute Sql String   ${sql}
                END
            END
            # Desconectar de la base de datos
            Disconnect From Database
            Log    Conexión cerrada exitosamente.    level=INFO
            ${completado}    Set Variable    ${True}
            ${error}    Set Variable     ${None} 
            BREAK
        EXCEPT      AS    ${error}
            Log     ${error}    level=ERROR
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}

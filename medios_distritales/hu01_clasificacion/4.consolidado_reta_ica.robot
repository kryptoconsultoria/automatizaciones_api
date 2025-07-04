*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           Dialogs
Resource          ${EXECDIR}/funciones/leer_pdf.robot
Resource          ${EXECDIR}/funciones/descargar_onedrive.robot


*** Variables ***
${config_file}    ../config.yaml
${config_file_pdf}    ../config_pdf.yaml
${REGEX_EXP}    \\$\\d{1,3}(?:,\\d{3})*
${REGEX_EXP_NIT}  \\b\\d{2}\\s\\d{5,}\\b
  

*** Tasks ***
LLenar Rete Ica
    [Documentation]    Clasifica formatos de la Dian
    ${yaml_content}    Read File    ${config_file}
    ${yaml_content_pdf}    Read File    ${config_file_pdf}
    ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    ${config_pdf}      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
    &{parametros}=    Create Dictionary    config_file=&{config}    config_pdf=&{config_pdf}
    consolidado_rete_ica    &{parametros}

*** Keywords ***
consolidado_rete_ica
    [Documentation]    extraccion de consolidado ICA
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${rete_ica}    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   rete_ica
            ${rete_ica_2}    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   rete_ica_2
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


            # Obtener cliente a procesar
            ${cliente}=   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}


            ${sql}     Catenate  
            ...    TRUNCATE TABLE consolidado_rete_ica
            Execute Sql String   ${sql}

            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${ruta_completa}    Replace String    ${CURDIR}/../${rete_ica["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${rete_ica["ruta_nube"]}    CLIENTE   ${cliente}


            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_insumos}    Set Variable    ${CURDIR}/../insumos
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_insumos}
            IF    not ${existe}
                Create Directory    ${ruta_insumos}
            END
            
            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_rete_ica}    Set Variable    ${CURDIR}/../insumos/rete_ica
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_rete_ica}
            IF    not ${existe}
                Create Directory    ${ruta_rete_ica}
            END

            # Crear carpeta si no existe cliente
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_completa}
            IF    not ${existe}
                Create Directory    ${ruta_completa}
            END

            #Borrar archivos de cada carpeta
            Remove Files    ${ruta_completa}/*


            #Enlistar archivo de sharepoint
            ${estado}    ${archivos}=     Listar archivos    refresh_token=${token_refresco}     secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}   nombre_del_sitio=${sharepoint['nombre_sitio']}    ruta_carpeta=${ruta_nube}    id_cliente=${sharepoint['id_cliente']}       
            IF    '${estado}' == 'No encontrado'
                ${completado}=    Set Variable    ${True}
                RETURN    ${completado}
            END
            
            FOR    ${archivo}  IN   @{archivos}
                #Descargar archivo de sharepoint
                ${archivo}    Convert To String    item=${archivo}
                ${archivo}    Replace String    search_for=File:    string=${archivo}    replace_with=${empty}
                ${archivo}    Strip String    string=${archivo}
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${ruta_completa}
                IF  '${estado_descarga}' == 'Fallido'
                    ${completado}=    Set Variable    ${False}
                    RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                    CONTINUE
                END
            END
             #==================================================================================
            ${archivos}=    OperatingSystem.List Files In Directory    ${ruta_completa}

            FOR    ${file}    IN    @{archivos}
                ${archivo}    Set Variable         ${ruta_completa}${file}

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
                    FOR    ${key}    IN    @{rete_ica.keys()}
                        ${es_regex}=    Evaluate    'ruta' in '''${key}'''
                        ${es_regex_2}=    Evaluate    'documento' in '''${key}'''
                        IF    not ${es_regex} and not ${es_regex_2}
                            ${matches}    Get Regexp Matches    ${informacion}     ${REGEX_EXP}
                            ${matches_ancho}    Get Length     ${matches}       
                            # Primer reemplazo: escapa '('
                            ${regex_texto}=    Replace String    string=${rete_ica_2}[${key}]    search_for=(        replace_with=\\(
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

                    ${sql}    Catenate
                    ...    llenar con update o isnert
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
            #==================================================================================
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN   ${completado}




*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           JSONLibrary
Resource          ../funciones/back_claude.robot
Resource          ../funciones/descargar_onedrive.robot


# *** Variables ***
# ${config_file}    ../config.yaml
# ${config_file_pdf}    ../config_pdf.yaml


# *** Tasks ***
# LLenar PDF 1003
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}=    Read File    ${config_file}
#     ${yaml_content_pdf}=    Read File    ${config_file_pdf}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
#     Formato 1003    ${config}    ${config_pdf}


*** Keywords ***
1003
    [Documentation]    Lee archivos PDF, extrae información utilizando expresiones regulares y clasifica los datos en la base de datos correspondiente
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    3
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${token_claude}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    claude
            ${pdf_1003}=    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   pdf_1003
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            # Iterar sobre cada ruta en rutas_locales
            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${carpeta_1003}    Replace String    ${pdf_1003["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${pdf_1003["ruta_nube"]}    CLIENTE   ${cliente}

            #Borrar archivos de cada carpeta
            OperatingSystem.Remove Files    ${carpeta_1003}/*

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
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${carpeta_1003}
                IF  '${estado_descarga}' == 'Fallido'
                  ${completado}=    Set Variable    ${False}
                  RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                  CONTINUE
                END
            END
            #==================================================================================

            ${archivos}=    OperatingSystem.List Files In Directory    ${carpeta_1003}

            FOR    ${file}    IN    @{archivos}

                ${archivo}=    Set Variable   ${carpeta_1003}/${file}

                # Leer el contenido del PDF utilizando OCR
                ${pdf_base64}=    Convertir a base 64    ${archivo}    Password=901814021
                ${prompt}    Replace String    string=${pdf_1003["prompt"]}    search_for=BUSINESS_COMPANY    replace_with=${cliente}
                ${resultado}=    Prompt Claude    ${token_claude["token"]}    ${pdf_1003["modelo"]}    ${prompt}    ${pdf_base64}

                ${resultado_json}=    Evaluate    json.loads('''${resultado}''')    json



                ${nit}=    Set Variable    ${resultado_json["NumId"]}
                ${dv}=    Set Variable    ${resultado_json["DV"]}
                ${razon_social}=    Set Variable    ${resultado_json["RazonSocial"]}
                ${primer_apellido}=    Set Variable    ${resultado_json["PrimerApellido"]}
                ${segundo_apellido}=    Set Variable    ${resultado_json["SegundoApellido"]}
                ${primer_nombre}=    Set Variable    ${resultado_json["PrimerNombre"]}
                ${otros_nombres}=    Set Variable    ${resultado_json["OtrosNombres"]}

                # Filtrar conceptos mayores a 0
                ${diccionario_filtrado}=    Create Dictionary
                FOR    ${clave}    ${valor}    IN    &{resultado_json}
                    Continue For Loop If    '${clave}' == 'NumId'
                    Continue For Loop If    '${clave}' == 'DV'
                    Continue For Loop If    '${clave}' == 'RazonSocial'
                    Continue For Loop If    '${clave}' == 'PrimerApellido'
                    Continue For Loop If    '${clave}' == 'SegundoApellido'
                    Continue For Loop If    '${clave}' == 'PrimerNombre'
                    Continue For Loop If    '${clave}' == 'OtrosNombres'
                    Set To Dictionary    ${diccionario_filtrado}    ${clave}    ${valor}
                END

                ${filtered_json}=    Evaluate    json.dumps(${diccionario_filtrado}, indent=4)    json

                # Iterar sobre el diccionario filtrado
                FOR    ${clave}    ${valor}    IN    &{diccionario_filtrado}
                    ${sql}=    Catenate    
                    ...    INSERT INTO formato_1003 (Concepto,NumId,DV,PrimerApellido,SegundoApellido,PrimerNombre,OtrosNombres,RazonSocial,ValorPagoRet,RetPract,Usuario) 
                    ...    VALUES('${clave}','${nit}','${dv}','${primer_apellido}','${segundo_apellido}',
                    ...    '${primer_nombre}','${otros_nombres}','${razon_social}','${valor["ValorPagoRet"]}','${valor["RetPract"]}','${usuario}')
                    Execute SQL String    ${sql}
                END

                Sleep    6
            END
            ${sql}=    Catenate    
            ...    DELETE FROM formato_1003 where ValorPagoRet='0' AND RetPract='0' AND Usuario='${usuario}'
            Execute SQL String    ${sql}

            ${sql}=    Catenate 
            ...    UPDATE formato_1003 a
            ...    INNER JOIN balances b  
            ...    ON TRIM(a.NumId) COLLATE utf8mb4_unicode_ci = TRIM(b.NumId) COLLATE utf8mb4_unicode_ci
            ...    SET a.TipoDoc = b.TipoDoc,
            ...    a.NumId = b.NumId,
            ...    a.DV = b.DV,
            ...    a.Direccion = b.Direccion,
            ...    a.RazonSocial = b.RazonSocial,
            ...    a.CodDpto = b.CodDpto,
            ...    a.CodMcp = b.CodMcp 
            ...    WHERE a.Usuario='${usuario}'

            Execute SQL String    ${sql}


            # Desconectar de la base de datos
            Disconnect From Database
            ${completado}=    Set Variable    ${True}
            ${error}    Set Variable     ${None}
            BREAK
        EXCEPT      AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}


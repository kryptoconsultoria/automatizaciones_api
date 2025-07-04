*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           Dialogs
Resource          ${EXECDIR}/funciones/leer_pdf.robot
Resource          ${EXECDIR}/funciones/descargar_onedrive.robot


*** Keywords ***
consolidado_ica
    [Documentation]    extraccion de consolidado ICA
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${ica}=    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   ica
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


            # Obtener cliente a procesar
            ${cliente}=   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            ${sql}     Catenate  
            ...    TRUNCATE TABLE consolidado_ica
            Execute Sql String   ${sql}



            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${carpeta_ica}    Replace String    ${CURDIR}/../${ica["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${ica["ruta_nube"]}    CLIENTE   ${cliente}

            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${ruta_completa}    Replace String    ${CURDIR}/../${ica["ruta_carpeta"]}    CLIENTE   ${cliente}
            ${ruta_nube}    Replace String    ${ica["ruta_nube"]}    CLIENTE   ${cliente}

            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_insumos}    Set Variable    ${CURDIR}/../insumos
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_insumos}
            IF    not ${existe}
                Create Directory    ${ruta_insumos}
            END
            
            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_ica}    Set Variable    ${CURDIR}/../insumos/ica
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_ica}
            IF    not ${existe}
                Create Directory    ${ruta_ica}
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
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${carpeta_ica}
                IF  '${estado_descarga}' == 'Fallido'
                    ${completado}=    Set Variable    ${False}
                    RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                    CONTINUE
                END
                BREAK
            END
            #==================================================================================
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN   ${completado}
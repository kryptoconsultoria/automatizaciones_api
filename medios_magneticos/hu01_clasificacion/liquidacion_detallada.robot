*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Resource          funciones/leer_pdf.robot
Resource          funciones/descargar_onedrive.robot
Resource          funciones/convertir_excel.robot
Resource          funciones/subir_insumo.robot


# *** Variables ***
# ${config_file}    ../config.yaml
# ${config_file_pdf}    ../config_pdf.yaml
# ${REGEX_TEXT}     [a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+(?:\\s+[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ]+)*
# ${REGEX_VALOR}    \\$(\\d{1,3}(?:,\\d{3})*)\\s*$  

# *** Tasks ***
# Planillas
#     [Documentation]    llenar formato_1009 y 1001 con información de las planillas
#     ${yaml_content}=    Read File    ${config_file}
#     ${yaml_content_pdf}=    Read File    ${config_file_pdf}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
#     planillas    ${config}    ${config_pdf}


*** Keywords ***
planillas
    [Documentation]    Lee archivos PDF, o exceles y extraer información correspondiente a afp;
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    3
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${token_claude}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    claude
            ${planillas}=    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   planillas
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=./logs/token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            ${sql}=    Catenate 
            ...    TRUNCATE TABLE planillas
            Execute SQL String    ${sql}
            Disconnect From Database

            # Iterar sobre cada ruta en rutas_locales
            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${carpeta_planillas}    Replace String    ${planillas["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${planillas["ruta_nube"]}    CLIENTE   ${cliente}

            #Borrar archivos de cada carpeta
            OperatingSystem.Remove Files    ${carpeta_planillas}/*

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
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${carpeta_planillas}
                IF  '${estado_descarga}' == 'Fallido'
                  ${completado}=    Set Variable    ${False}
                  RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                  CONTINUE
                END
            END

            # Iterar carpeta de archivos-

            ${archivos}=    RPA.FileSystem.List files in directory    ${carpeta_planillas}
            FOR    ${archivo}    IN    @{archivos}

                ${archivo}    Convert To String    item=${archivo}
                ${nombre_archivo}=    Get File Name    ${archivo}

                # Extraer nombre y extensión
                ${lista}=        Split String    ${nombre_archivo}    .
                ${extension}=    Get From List    ${lista}    -1
                ${nombre_base}=  Replace String   ${nombre_archivo}    search_for=.${extension}    replace_with=${EMPTY}

                # Construir rutas de archivo
                ${archivo_csv}=     Set Variable    ${carpeta_planillas}${nombre_base}.csv
                ${archivo_excel}=   Set Variable    ${carpeta_planillas}${nombre_base}.${extension}

                IF    '${extension}' == 'xlsx' or '${extension}' == 'xls'
                    Convertir Archivo CSV    ${archivo_excel}    ${planillas["nombre_hoja"]}    ${archivo_csv}
                    Ejecutar Carga Masiva desde CSV    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}    ${archivo_csv}    ${planillas["nombre_tabla"]}    ${planillas["cabeceras"]}    ${planillas["columnas"]}
                    
                    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
                    #================================================Extraccion de AFP
                    LISTA= 
                    FOR 
                        #Limitar y encontrar sección AFP
                        ${sql}    Catenate
                        ...    SELECT idPlanillas
                        ...    FROM planillas WHERE Riesgo LIKE '%AFP%'            
                        ${fila_inicial}    Query     ${sql}
                        ${inicio}    Evaluate    expression=${fila_inicial}[0][0]+1

                        #Limitar y encontrar sección ARL
                        ${sql}    Catenate
                        ...    SELECT idPlanillas
                        ...    FROM planillas WHERE Riesgo like '%ARL%'            
                        ${fila_limite}    Query     ${sql}
                        ${tiene_resultado}    Get Length    ${fila_limite}
                        IF    ${tiene_resultado} = 0
                            ${sql}    Catenate
                            ...    SELECT idPlanillas
                            ...    FROM planillas WHERE Riesgo like '%TOTAL%'            
                            ${fila_limite}    Query     ${sql}
                            ${tiene_resultado}=    Get Length    ${fila_limite}
                        END
                        ${fin}    Evaluate    expression=${fila_limite}[0][0]-1

                        #Actualizar valores AFP
                        ${sql}    Catenate
                        ...    SELECT TRIM(Riesgo),TRIM(ValorAPagar)
                        ...    FROM planillas WHERE IdPlanillas 
                        ...    BETWEEN  ${inicio} AND ${fin}

                        ${AFP}=    Query     ${sql}
                        FOR    ${fila}    IN    @{AFP}
                            ${riesgo}    Set Variable    ${fila}[0]
                            ${valor_a_pagar}    Set Variable    ${fila}[1]

                            ${sql}    Set Variable    UPDATE formato_1009 SET SaldoCtasPagar="${valor_a_pagar}" WHERE RazonSocial LIKE '%${riesgo}%'  
                            Execute SQL String    ${sql}
                        END
                    END
                END
            END
            ${completado}=    Set Variable    ${True}
            BREAK
        EXCEPT      AS    ${error}
            Disconnect From Database
            Log     ${error}    level=ERROR
            ${completado}=    Set Variable    ${False}
       END
   END
   RETURN    ${completado}
        
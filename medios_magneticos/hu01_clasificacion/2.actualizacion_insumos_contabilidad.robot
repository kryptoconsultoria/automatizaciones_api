*** Settings ***
Library    RPA.FileSystem
Library    Collections
Library    String
Library    OperatingSystem
Resource   ../funciones/convertir_excel.robot
Resource   ../funciones/descargar_onedrive.robot
Resource   ../funciones/subir_insumo.robot

# *** Variables ***
# ${config}    ../config.yaml
# ${REINTENTOS}    2

# *** Tasks ***
# Subir archivos a base de datos
#     [Documentation]    Lee las rutas locales de un archivo YAML y las procesa en un bucle.
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     actualizacion_insumos_contabilidad   ${config}

*** Keywords ***
actualizacion_insumos_contabilidad
    [Documentation]    Lee las rutas locales de un archivo YAML, procesa cada ruta y sube los archivos a la base de datos.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${rutas_contabilidad}   Get From Dictionary    ${parametros['config_file']}    rutas_contabilidad
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            #Conexion a sharepoint 
            ${token_refresco}    Get File    path=${CURDIR}/../logs/token.txt    encoding=UTF-8

            #Limpieza
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            Execute SQL Script    ${CURDIR}/../sql/limpieza_contabilidad.sql
            Execute SQL Script    ${CURDIR}/../sql/limpieza_balances.sql

            ${sql}    Catenate     
            ...    SELECT b.Nombre FROM cliente a 
            ...    INNER JOIN sistema b ON 
            ...    a.IdSistema=b.IdSistema where a.Nombre='${cliente}'
            
            
            ${nombre_sistema}    Query    ${sql}
            Disconnect From Database
            
            FOR    ${nombre_ruta}    IN    @{rutas_contabilidad.keys()}
                ${sistema_elegido}=    Run Keyword And Return Status    Should Contain    ${nombre_ruta}    ${nombre_sistema}[0][0] 

                IF    ${sistema_elegido}
                    ${ruta}=    Get From Dictionary    ${rutas_contabilidad}    ${nombre_ruta}
                    ${validar_insumos}     	Run Keyword And Return Status    Should Contain    ${ruta}    ${nombre_sistema}[0][0]    ignore_case=True
                    
                    #==================================================================================
                    # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
                    ${ruta_cliente}    Replace String    ${ruta["ruta_carpeta"]}    CLIENTE   ${cliente}
                    ${ruta_nube}    Replace String    ${ruta["ruta_nube"]}    CLIENTE   ${cliente}

                    #Borrar archivos de cada carpeta
                    OperatingSystem.Remove Files    ${ruta_cliente}*

                    #Enlistar archivo de sharepoint
                    ${estado}    ${archivos}    Listar archivos    refresh_token=${token_refresco}     secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}   nombre_del_sitio=${sharepoint['nombre_sitio']}    ruta_carpeta=${ruta_nube}    id_cliente=${sharepoint['id_cliente']}

                    FOR    ${archivo}  IN   @{archivos}
                        #Descargar archivo de sharepoint
                        ${archivo}    Convert To String    item=${archivo}
                        ${archivo}    Replace String    search_for=File:    string=${archivo}    replace_with=${empty}
                        ${archivo}    Strip String    string=${archivo}
                        ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${ruta_cliente}
                    END
                    #==================================================================================
                           
                    ${archivos}=    RPA.FileSystem.List files in directory    ${ruta_cliente}

                    FOR    ${archivo}    IN    @{archivos}
                        ${archivo_path}=    Convert To String    ${archivo}
                        ${nombre_archivo}=    Get File Name    ${archivo_path}

                        # Extraer nombre y extensión
                        ${lista}=        Split String    ${nombre_archivo}    .
                        ${nombre_base}=  Get From List    ${lista}    0
                        ${extension}=    Get From List    ${lista}    1

                        # Construir rutas de archivo
                        ${archivo_csv}=     Set Variable    ${ruta_cliente}${nombre_base}.csv
                        ${archivo_excel}=   Set Variable    ${ruta_cliente}${nombre_base}.${extension}

                        # Determinar acción según la extensión
                        IF    '${extension}' == 'xlsx' or '${extension}' == 'xls'
                            IF    '${ruta["nombre_tabla"]}' == 'balance_siigo_pyme'
                                #Completar valores nulos para insumos siigo pyme
                                Completar Valores Nulos    ${archivo_excel}    ${archivo_csv}    ${ruta["nombre_hoja"]}    ${ruta["indice_columna"]}
                            ELSE
                                Convertir Archivo CSV    ${archivo_excel}    ${ruta["nombre_hoja"]}    ${archivo_csv}
                            END
                        ELSE
                            Guardar CSV en UTF-8    ${archivo_csv}    ${archivo_csv}
                        END

                        # Subir archivo procesado a la base de datos
                        Ejecutar Carga Masiva desde CSV     nombre_bd=${bd_config["nombre_bd"]}    usuario=${bd_config["usuario"]}    contrasena=${bd_config["contrasena"]}    host=${bd_config["servidor"]}    puerto=${bd_config["puerto"]}    archivo_csv=${ruta["nombre_tabla"]}    cabeceras=${ruta["cabeceras"]}    columnas=${ruta["columnas"]}    usuario_sistema=${usuario}
                        OperatingSystem.Remove File    ${archivo_csv}
                    END
                END
            END
            ${completado}=    Set Variable    ${True}
            BREAK
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    Return From Keyword    ${completado}
    
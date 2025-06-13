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
#     Subir archivos a base de datos admin    ${config}

*** Keywords ***
actualizacion_insumos_admin
    [Documentation]    Lee las rutas locales de un archivo YAML, procesa cada ruta y sube los archivos a la base de datos.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${rutas_admin}   Get From Dictionary    ${parametros['config_file']}    rutas_admin
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint

            #Conexion a sharepoint 
            ${token_refresco}    Get File    path=${CURDIR}/../logs/token.txt    encoding=UTF-8

            #Limpieza
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            ${sql}      Execute SQL Script    ${CURDIR}/../sql/limpieza_admin.sql
            Disconnect From Database

            #Subida de insumos administración
            FOR    ${nombre_ruta}    IN    @{rutas_admin.keys()}
                ${ruta}=    Get From Dictionary    ${rutas_admin}    ${nombre_ruta}
                ${validar_insumos}     	Run Keyword And Return Status    Should Not Contain    ${ruta}    insumos    ignore_case=True
                
                #==================================================================================
                # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
                # Borrar archivos de cada carpeta
                OperatingSystem.Remove Files    ${ruta["ruta_carpeta"]}/*

                #Enlistar archivo de sharepoint
                ${estado}    ${archivos}    Listar archivos    refresh_token=${token_refresco}     secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}   nombre_del_sitio=${sharepoint['nombre_sitio']}    ruta_carpeta=${ruta["ruta_nube"]}    id_cliente=${sharepoint['id_cliente']}
                IF    '${estado}' == 'No encontrado'
                    ${completado}=    Set Variable    ${True}
                    Disconnect From Database
                    RETURN    ${completado}
                END
                
                
                FOR    ${archivo}  IN   @{archivos}
                    #Descargar archivo de sharepoint
                    ${archivo}    Convert To String    item=${archivo}
                    ${archivo}    Replace String    search_for=File:    string=${archivo}    replace_with=${empty}
                    ${archivo}    Strip String    string=${archivo}
                    ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}      id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta["ruta_nube"]}${archivo}     ruta_descarga=${ruta["ruta_carpeta"]}
                END
                
                IF  not $estado_descarga
                    BREAK
                END
                #==================================================================================
        
                ${archivos}=    RPA.FileSystem.List files in directory    ${ruta["ruta_carpeta"]}
                    
                FOR    ${archivo}    IN    @{archivos}
                    ${archivo_path}=    Convert To String    ${archivo}
                    ${nombre_archivo}=    Get File Name    ${archivo_path}

                    # Extraer nombre y extensión
                    ${lista}=        Split String    ${nombre_archivo}    .
                    ${nombre_base}=  Get From List    ${lista}    0
                    ${extension}=    Get From List    ${lista}    1

                    # Construir rutas de archivo
                    ${archivo_csv}=     Set Variable    ${ruta["ruta_carpeta"]}${nombre_base}.csv
                    ${archivo_excel}=   Set Variable    ${ruta["ruta_carpeta"]}${nombre_base}.${extension}
                    # Determinar acción según la extensión
                    IF    '${extension}' == 'xlsx' or '${extension}' == 'xls'
                        Convertir Archivo CSV    ${archivo_excel}    ${ruta["nombre_hoja"]}    ${archivo_csv}
                    ELSE
                        Guardar CSV en UTF-8    ${archivo_csv}    ${archivo_csv}
                    END

                    # Subir archivo procesado a la base de datos
                    Ejecutar Carga Masiva desde CSV    nombre_bd=${bd_config["nombre_bd"]}    usuario=${bd_config["usuario"]}    contrasena=${bd_config["contrasena"]}    host=${bd_config["servidor"]}    puerto=${bd_config["puerto"]}    archivo_csv=${archivo_csv}    nombre_tabla=${ruta["nombre_tabla"]}    cabeceras=${ruta["cabeceras"]}    columnas=${ruta["columnas"]}
                
                    # Borrar archivos de excel y csv
                    OperatingSystem.Remove File    ${archivo_csv}
                END
            END
            ${completado}=    Set Variable    ${True}
            BREAK
        EXCEPT     AS    ${error}
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}
    
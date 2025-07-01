*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String

*** Variables ***
${CONFIG_FILE}    ../config.yaml


*** Tasks ***
Retenciones Asumidas
    [Documentation]    Agrupa retenciones asumidas
    # Leer y cargar la configuración desde el archivo YAML
    ${yaml_content}=    Read File    ${config_file}   
    ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    Retenciones Asumidas    ${config_file}


*** Keywords ***
Retenciones Asumidas
    [Documentation]    Lee archivos PDF, extrae información utilizando expresiones regulares y clasifica los datos en la base de datos correspondiente
    [Arguments]    ${config_file}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${bd_config}=       Get From Dictionary    ${config_file['credenciales']}    base_datos
            ${sharepoint}   Get From Dictionary   ${config_file['credenciales']}   sharepoint
            ${cliente}   Get From Dictionary   ${config_file['credenciales']}   cliente

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            Log    Conexión exitosa con la base de datos: ${bd_config["nombre_bd"]}    level=INFO


            # Iterar sobre cada ruta en rutas_locales
            ${cliente}=    Query    SELECT IdCliente FROM cliente WHERE Nombre='${cliente}'

            ${sql}=    Catenate    
            ...    SELECT * FROM automatizaciones.retenciones_asumidas WHERE IdCliente='${cliente}[0][0]'   
            ${Estado}=    Query       ${sql}
    
            FOR     ${fila}    IN    @{Estado}

                ${cuenta_principal}    Set Variable    ${fila}[1]
                ${cuenta_secundaria}   Set Variable    ${fila}[2]
                ${columna}           Set Variable    ${fila}[3]
                ${id_cliente}    Set Variable    ${fila}[4]
           
                ${sql}=    Catenate
                ...    SELECT Codigo,NumId,SUM(${columna})
                ...    from formato_1001 group by Numid,Codigo 
                ...    HAVING Codigo,NumId LIKE '%${cuenta_principal}'
                ${cuenta_principal}    Query       ${sql}


                ${sql}    Catenate
                ...    SELECT Codigo,NumId,SUM(${columna})
                ...    from formato_1001 group by Numid,Codigo 
                ...    HAVING Codigo,NumId LIKE '%${cuenta_secundaria}'
                ${cuenta_secundaria}    Query       ${sql}

                ${total}    Evaluate    ${cuenta_principal}[0][2]-${cuenta_secundaria}[0][2]

                ${sql}    Catenate 
                ...    DELETE FROM 
                Execute SQL String    ${sql}
            END
            # Desconectar de la base de datos
            Disconnect From Database
        EXCEPT      AS    ${error}
         Disconnect From Database
         Log     ${error}    level=ERROR
         ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}








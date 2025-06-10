*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           JSONLibrary
Resource          ../funciones/back_perplexity.robot


*** Variables ***
${config_file}    ../config.yaml
${config_file_pdf}    ../config_pdf.yaml


*** Tasks ***
Consulta de terceros
    [Documentation]    Consultar terceros en perplexity
    ${yaml_content}=    Read File    ${config_file}
    ${yaml_content_pdf}=    Read File    ${config_file_pdf}
    ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    Consultar Terceros   ${config}


*** Keywords ***
consultar_terceros
    [Documentation]    Lee archivos PDF, extrae información utilizando expresiones regulares y clasifica los datos en la base de datos correspondiente
    [Arguments]    ${config}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${token_perplexity}=       Get From Dictionary    ${config['credenciales']}    perplexity
            ${bd_config}=       Get From Dictionary    ${config['credenciales']}    base_datos
            
            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            Log    Conexión exitosa con la base de datos: ${bd_config["nombre_bd"]}    level=INFO

            # Iterar sobre terceros internacionales
            ${sql}=    Catenate    
            ...    SELECT ANY_VALUE(idBalances),NumId,RazonSocial,Municipio FROM  balances WHERE PaisResidencia !='169' 
            ...    OR NumId like '%333333%' OR NumId like '%444444%' group by NumId,RazonSocial,Municipio
            
            ${resultados}=    Query       ${sql}
            

            FOR    ${fila}    IN    @{resultados}

                ${id_fila}    Set Variable    ${fila}[0]
                ${num_id}            Set Variable    ${fila}[1]
                ${razon_social}            Set Variable    ${fila}[2]
                ${municipio}            Set Variable    ${fila}[3]
                

                ${instrucciones}    Replace String     string=${token_perplexity['instrucciones']}     search_for=BUSINESS_NAME    replace_with=${razon_social}
                ${instrucciones}    Replace String     string=${instrucciones}    search_for=CITY_HEADQUATERS    replace_with=${municipio}


                # Buscar en internet
                ${resultado}=    Prompt Perplexity    ${token_perplexity['token']}    ${token_perplexity['modelo']}    ${token_perplexity['prompt']}    ${instrucciones}    

                ${resultado_json}=    Evaluate    json.loads('''${resultado}''')    json

                Log     ${resultado_json}    level=DEBUG

                ${sql}=    Catenate    
                ...    INSERT INTO  informacion_terceros  
                ...    (RazonSocial,HeadquarterAddress,HeadquarterCountry,HeadquarterCity,HeadquarterIdNumber,ColombiaAddress,ColombiaCity,NumId)
                ...    VALUES ("${razon_social}","${resultado_json['HeadquarterAddress']}","${resultado_json['HeadquarterCountry']}","${resultado_json['HeadquarterCity']}",
                ...    "${resultado_json['HeadquarterIdNumber']}","${resultado_json['ColombiaAddress']}","${resultado_json['ColombiaCity']}","${num_id}")
                Execute SQL String    ${sql}
            END

            ${sql}=    Catenate 
            ...    UPDATE balances a
            ...    INNER JOIN informacion_terceros b
            ...    ON a.RazonSocial COLLATE utf8mb4_unicode_ci = b.RazonSocial COLLATE utf8mb4_unicode_ci
            ...    AND a.NumId = b.NumId
            ...    SET a.DV = IF(b.ColombiaAdddres != '',b.ColombiaAddress,b.HeadquarterAddress),
            ...    a.RazonSocial = '',
            ...    a.Direccion = IF(b.ColombiaAdddres != '',b.ColombiaAddress,b.HeadquarterAddress),
            ...    a.NumId = IF(b.ColombiaAdddres != '',b.ColombiaAddress,b.HeadquarterAddress),
            ...    a.City = IF(b.ColombiaCity != '',b.ColombiaCity,b.HeadquarterCity);

            Log   ${sql}  console=True
            Execute SQL String    ${sql}

            # Desconectar de la base de datos
            Disconnect From Database
            Log    Conexión cerrada exitosamente.    level=INFO
            ${completado}=    Set Variable    ${True}
            BREAK
        EXCEPT      AS    ${error}
            Log     ${error}    level=ERROR
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    [return]    ${completado}
        


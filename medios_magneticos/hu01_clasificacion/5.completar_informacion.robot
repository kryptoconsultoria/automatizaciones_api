*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Resource          ../funciones/completar_informacion_dian.robot

#*** Variables ***
#${config}    ../config.yaml

# *** Test Cases ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Completar Informacion    ${config}      ${True}   

# Clasificar En Formatos 2
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Completar Informacion    ${config}    ${False}  

*** Keywords ***
completar_informacion
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    ${procesos}    Set Variable    3
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${columnas}=    Get From Dictionary    ${parametros['config_file']}    formatos
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            ${sql}=    Catenate 
            ...    UPDATE balances a
            ...    INNER JOIN persona_natural b ON a.NumId = b.NumId
            ...    SET
            ...    a.PrimerApellido = IF(b.EncontradoDian='NO',a.PrimerApellido,b.PrimerApellido),
            ...    a.SegundoApellido = IF(b.EncontradoDian='NO',a.SegundoApellido,b.SegundoApellido),
            ...    a.PrimerNombre = IF(b.EncontradoDian='NO',a.PrimerNombre,b.PrimerNombre),
            ...    a.OtrosNombres = IF(b.EncontradoDian='NO',a.OtrosNombres,b.OtrosNombres),
            ...    a.EncontradoDian = b.EncontradoDian,
            ...    a.RazonSocial=IF(b.EncontradoDian='NO',a.RazonSocial,'');
            
            Execute SQL String    ${sql}

            ${sql}=    Catenate    
            ...    SELECT ANY_VALUE(idBalances) AS idBalance, NumId, TipoDoc
            ...    FROM automatizaciones.balances
            ...    WHERE (DV = '' OR TipoDoc IN ('13', '41', '22'))
            ...    AND EncontradoDian IS NULL AND NumId IS NOT NULL    
            ...    AND NumId REGEXP '^[0-9]+$'
            ...    GROUP BY NumId, TipoDoc;
            
            ${resultados}=    Query       ${sql}
            
            FOR    ${fila}    IN    @{resultados}
                ${num_id}           Set Variable    ${fila}[1]
                ${tipo_doc}          Set Variable    ${fila}[2]

                ${datos}    ${completado}=     Consulta DIAN     ${num_id}

                IF    $datos is not None and $completado is True
                    IF  $datos[1] == "REGISTRO ACTIVO"
                        IF    "${tipo_doc}" == "13" or "${tipo_doc}" == "41" or "${tipo_doc}" == "22"
                            ${sql}=    Catenate    
                            ...    UPDATE balances SET DV='${datos[0]}', 
                            ...    PrimerApellido='${datos[2]}', SegundoApellido='${datos[3]}', 
                            ...    PrimerNombre='${datos[4]}', OtrosNombres='${datos[5]}',
                            ...    RazonSocial='',EncontradoDian='SI' WHERE NumId='${num_id}'

                            ${sql}=    Catenate    
                            ...    INSERT INTO persona_natural (NumId,DV,PrimerApellido,
                            ...    SegundoApellido,PrimerNombre,OtrosNombres,EncontradoDian) 
                            ...    VALUES ('${num_id}','${datos[0]}','${datos[2]}',
                            ...    '${datos[3]}','${datos[4]}','${datos[5]}','SI')

                            Execute SQL String    ${sql}
                        ELSE
                            ${sql}=    Set Variable    UPDATE balances SET DV='${datos[0]}',EncontradoDian='SI' WHERE NumId='${num_id}'
                        END
                    END
                ELSE
                    ${sql}=    Catenate    
                    ...    UPDATE balances SET EncontradoDian='NO' WHERE NumId='${num_id}'
                    Execute SQL String    ${sql}
                    
                    ${sql}=    Catenate    
                    ...    INSERT INTO persona_natural (NumId,EncontradoDian) 
                    ...    VALUES ('${num_id}','NO')
                    Execute SQL String    ${sql}    
                END
            END
            Disconnect From Database
            ${completado}=    Set Variable    ${True}

        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    [return]    ${completado}

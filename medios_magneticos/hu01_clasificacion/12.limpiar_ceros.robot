*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs


# *** Variables ***
# ${config}    ../config.yaml

# *** Tasks ***
# Limpiar ceros dian
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Limpiar ceros    ${config}  

*** Keywords ***
Limpiar ceros
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${columnas}=    Get From Dictionary    ${parametros['config_file']}    formatos
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${sumatorias}    Get From Dictionary    ${parametros['config_file']}    sumatorias
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
 
            ${id_sistema}=    Query    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,IdDepartamento,IdMunicipio,Direccion,DV FROM cliente where Nombre='${cliente}'
            
            ${resultados}=    Query    SELECT * FROM Formato WHERE Formato NOT IN ('formato_2276','formato_1010')

            FOR    ${fila}    IN    @{resultados}

                ${formato}           Set Variable    ${fila}[1]
                ${cuantias_menores}          Set Variable    ${fila}[2]
                ${cuantias_menores}    Convert To String    ${cuantias_menores}
        
                ${sumatorias_formato}         Set Variable    ${sumatorias}[${formato}]
                ${sumatorias_list}    Split String    string=${sumatorias_formato}    separator=,
                ${contador}    Set Variable    1

                ${columna_din_4}    Set Variable    ${EMPTY}

                FOR      ${item}    IN    @{sumatorias_list}
                    ${columna_formula}      Set Variable    ${item} IN ('0',NULL,'')  
                    IF   ${contador} != 1
                        ${columna_din_4}        Set Variable    ${columna_din_4} AND ${columna_formula}
                    ELSE
                        ${columna_din_4}        Set Variable    ${columna_formula}
                    END
                    ${contador}      Evaluate     ${contador}+1
                END


                ${sql}    Catenate 
                ...    DELETE FROM ${formato} WHERE
                ...    ${columna_din_4} AND Usuario='${usuario}';

                Execute SQL String    ${sql}    
            END
            ${completado}=    Set Variable    ${True}
            Disconnect From Database
        EXCEPT     AS    ${error}
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}










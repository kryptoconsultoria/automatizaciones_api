*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs
Library           RPA.Excel.Files
Library           RPA.Tables
Library           DateTime


# *** Variables ***
# ${CONFIG}    ../config.yaml
# ${REINTENTOS}    2

# *** Tasks ***
# Correr Exportar a excel
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_file}     Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     &{parametros}    Create Dictionary    config_file=&{config_file}
#     exportar_excel   &{parametros}


*** Keywords ***
Encontrar Claves Con Término
    [Arguments]    @{lista_json}    ${termino}
    ${resultados}=    Create List
    ${termino_lower}=    Convert To Lower Case    ${termino}
    ${longitud}=    Get Length    ${lista_json}
    FOR    ${i}    IN RANGE    ${longitud}
        ${dic_actual}=    Get From List    ${lista_json}    ${i}
        FOR    ${clave}    ${valor}    IN    &{dic_actual}
            ${valor_str}=    Convert To String    ${valor}
            ${valor_lower}=    Convert To Lower Case    ${valor_str}
            ${contiene}=    Run Keyword And Return Status    Should Contain    ${termino_lower}    ${valor_lower}
            IF    ${contiene}
                ${par}=    Create List    ${clave}    ${i}
                Append To List    ${resultados}    ${par}
                BREAK
            END
        END
        IF    ${contiene}
            BREAK
        END
    END
    [Return]    ${resultados}
    

exportar_excel
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${REINTENTOS}
        TRY
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${output}       Get From Dictionary    ${parametros['config_file']}    output
            ${columnas}    Get From Dictionary    ${parametros['config_file']}    formatos
            ${sumatorias}    Get From Dictionary    ${parametros['config_file']}    sumatorias
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            ${fecha_actual}    Get Current Date    result_format=%Y-%m-%d_%H_%M_%S

            ${excel_ruta}    Set Variable   ${output['salidas']}${/}exogena_${cliente}_desglosado_${fecha_actual}.xlsx
            OperatingSystem.Copy File    ${output['ruta_desglose']}    ${excel_ruta}
            
            Open Workbook     ${excel_ruta}      data_only=True

            ${resultados}=    Query    SELECT Formato FROM formato

            FOR    ${fila}    IN    @{resultados}
                ${formato}    Set Variable    ${fila}[0]
                ${columna_din}         Set Variable    ${columnas}[${formato}],${sumatorias}[${formato}]
                ${primera_columna}    Split String    string=${columna_din}    separator=,

                Set Active Worksheet    ${formato}

                # Leer toda la hoja activa como lista de filas (listas internas)
                @{rows}=    Read Worksheet As Table    header=False    trim=${false}

                @{posicion}    Encontrar Claves Con Término     @{rows}    termino=${primera_columna}[0]
                ${numero_fila}    Set Variable   ${posicion}[0][1]
                ${numero_fila}    Evaluate    ${numero_fila}+2
                ${columna}    Set Variable   ${posicion}[0][0]                

                # registrar cada fila de cada formato en su respectiva hoja de excel                
                ${resultados}    Query    SELECT ${columna_din} FROM ${formato} WHERE Usuario='${usuario}'
                
                # Llenar todas las filas en bloque
                ${resultados_lista}    Evaluate    list(map(list, ${resultados}))

                Set Cell Values    start_cell=${columna}${numero_fila}    values=${resultados_lista}
            END

            Save Workbook
            Disconnect From Database
            Close Workbook
            ${completado}=    Set Variable    ${True}
            BREAK   
        EXCEPT     AS    ${error}
            ${completado}=    Set Variable    ${False}
        END
    END
    [return]    ${completado}
        


















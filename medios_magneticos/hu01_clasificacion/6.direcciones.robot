*** Settings ***
Library           ${EXECDIR}/librerias/LibreriaGPT.py
Library           OperatingSystem
Library           String
Library           Collections
Library           DatabaseLibrary
Resource          ${EXECDIR}/funciones/limpiar_texto.robot

#*** Variables ***
# ${CONFIG}    ../config.yaml

# *** Tasks ***
# Arreglar Direcciones
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Direcciones   ${config}


*** Keywords ***
direcciones
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${columnas}    Get From Dictionary    ${parametros['config_file']}    formatos
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            ${resultados}=     Query    SELECT NumId,direccion FROM balances WHERE direccion IS NOT NULL AND Direccion !='' AND Usuario='${usuario}'

            FOR    ${fila}    IN    @{resultados}

                ${num_id}    Set Variable    ${fila}[0]
                ${direccion}    Set Variable    ${fila}[1]

                @{entidades_direccion}    Extraer Entidades De Direccion    texto=${direccion}

                ${lista_abreviatura}    Create List 
                
                FOR    ${elemento}    IN    @{entidades_direccion}
                    ${sql}    Set Variable    SELECT Abreviatura FROM direccion WHERE Significado='${elemento}[1]'
                    ${abreviatura}     Query    ${sql}    
                    Append To List    ${lista_abreviatura}    ${abreviatura}[0][0]
                END

                Reverse List     ${lista_abreviatura}

                ${direccion_arreglada}    Reemplazar Entidades De Direccion    ${direccion}    ${entidades_direccion}    ${lista_abreviatura}


                ${sql}    Set Variable    UPDATE balances SET direccion="${direccion_arreglada}" WHERE NumId='${num_id}'
                
                Execute SQL String    ${sql}
            END
            Disconnect From Database
            ${completado}=    Set Variable    ${True}
            ${error}    Set Variable     ${None}
            BREAK
        EXCEPT     AS    ${error}
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}







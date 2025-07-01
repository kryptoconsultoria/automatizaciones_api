*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs

# *** Variables ***
# ${CONFIG}    ../config.yaml

# *** Tasks ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     limpiar_puc   ${config}


*** Keywords ***
limpiar_puc
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            ${sql}      Execute SQL Script    ${CURDIR}/../sql/limpieza_balances.sql
            ${sql}      Execute SQL Script    ${CURDIR}/../sql/tablas_temporales.sql


            ${id_sistema}    Query    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,IdDepartamento,IdMunicipio,Direccion FROM cliente where Nombre='${cliente}'
            ${sql}    Catenate
            ...    SELECT *
            ...    FROM puc a INNER JOIN 
            ...    cliente b ON b.IdCliente=a.IdCliente
            ...    Where  b.Nombre='${cliente}'
            ...    order by Formato,CuentaContable ASC


            ${resultados}=    Query     ${sql}     

            FOR    ${fila}    IN    @{resultados}

                ${id_fila}    Set Variable    ${fila}[0]
                ${cuenta_contable}    Set Variable    ${fila}[1]

                ${sql}    Catenate
                ...    SELECT Count(*) FROM puc a
                ...    INNER JOIN 
                ...    cliente b ON b.IdCliente=a.IdCliente
                ...    where CuentaContable like '${cuenta_contable}%'
                ...    AND b.Nombre='${cliente}'

                ${conteo}    Query    ${sql}

                IF     $conteo[0][0] > 1
                   ${sql}    Catenate
                   ...    DELETE FROM puc WHERE IdPuc=${id_fila}
                   Execute Sql String   ${sql} 
                END
            END
            Disconnect From Database
            ${completado}=    Set Variable    ${True}
            ${error}    Set Variable     ${None}
            BREAK
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}

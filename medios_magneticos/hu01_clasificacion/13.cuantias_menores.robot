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
# Correr cuantias menores
#     ${yaml_content}=    Read File    ${config}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Cuantias Menores    ${config}  

*** Keywords ***
cuantias_menores
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
            Log    Conexión exitosa con la base de datos: ${bd_config["nombre_bd"]}

            ${sql}    Catenate 
            ...    SELECT IdFormato,Formato,CuantiasMenores,Formula 
            ...    FROM formato a INNER JOIN formulas b ON a.IdFormula=b.IdFormula 
            ...    WHERE CuantiasMenores > 0           
            ${resultados}=    Query  ${sql}
        
            ${id_sistema}=    Query    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,IdDepartamento,IdMunicipio,Direccion,DV FROM cliente where Nombre='${cliente}'
            

            FOR    ${fila}    IN    @{resultados}

                ${formato}           Set Variable    ${fila}[1]
                ${cuantias_menores}          Set Variable    ${fila}[2]
                ${cuantias_menores}    Convert To String    ${cuantias_menores}
                
                ${formula_cuantia}          Set Variable    ${fila}[3]
                ${formula_cuantia}    Replace String    ${formula_cuantia}    VALOR_CUANTIA    ${cuantias_menores} 

                ${columna_din}         Set Variable    ${columnas}[${formato}]

                ${sumatorias_formato}         Set Variable    ${sumatorias}[${formato}]
                ${columna_din_l}    Set Variable     ${columna_din},${sumatorias_formato}


                ${contador}    Set Variable    1
                ${columna_din_4}    Set Variable    ${EMPTY}
                ${columna_din_5}    Set Variable    ${EMPTY}
                
                ${sumatorias_list}    Split String    ${sumatorias_formato}    ,
                
                FOR      ${item}    IN    @{sumatorias_list}
                    ${columna_formula}      Set Variable    SUM(${item})
                    IF   ${contador} != 1
                        ${columna_din_4}        Set Variable    ${columna_din_4},${columna_formula}
                    ELSE
                        ${columna_din_4}        Set Variable    ${columna_formula}
                    END
                    ${contador}      Evaluate     ${contador}+1
                END

                ${columnas_list}    Split String    ${columna_din}    ,
                ${contador}    Set Variable    1

                FOR      ${item}    IN    @{columnas_list}
                    ${columna_formula_2}      Set Variable    ANY_VALUE(${item}) 
                    IF   ${contador} != 1
                        ${columna_din_5}        Set Variable    ${columna_din_5},${columna_formula2}
                    ELSE
                        ${columna_din_5}        Set Variable    ${columna_formula2}
                    END
                    ${contador}      Evaluate     ${contador}+1
                END

                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(Concepto)     '5001' AS Concepto
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(NumId)     '222222222' AS NumId
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(TipoDoc)     '43' AS TipoDoc
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(RazonSocial)     'Cuantias Menores' AS RazonSocial
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(IdPais)     '${id_sistema}[0][4]' AS IdPais
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(CodDpto)     '${id_sistema}[0][5]' AS CodDpto   
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(CodMcp)     '${id_sistema}[0][6]' AS CodMcp   
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(Direccion)     '${id_sistema}[0][7]' AS Direccion 
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(PrimerApellido)    '' AS PrimerApellido
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(SegundoApellido)     '' AS SegundoApellido
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(PrimerNombre)     '' AS PrimerNombre
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(OtrosNombres)     '' AS OtrosNombres
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(DV)     '' AS DV
                ${columna_din_5}    Replace String    ${columna_din_5}    ANY_VALUE(PaisResidencia)     '169' AS PaisResidencia


                 ${sql}    Catenate    INSERT INTO ${formato}_cuantias (${columna_din_l},'${usuario}')
                ...    SELECT ${columna_din_l},'${usuario}'
                ...    FROM (SELECT  ${formula_cuantia} AS Agrupar,
                ...    a.* FROM ${formato} a WHERE Usuario='${usuario}'
                ...    ) b
                ...    WHERE Agrupar = 'X'
                Execute SQL String    ${sql}


                ${sql}    Catenate    CREATE TEMPORARY TABLE IF NOT EXISTS cuantias_menores_temp
                ...    SELECT  ${columna_din_5},${columna_din_4},Usuario from ${formato}_cuantias
                ...    UNION ALL
                ...    SELECT ${columna_din_l}
                ...    FROM (SELECT  ${formula_cuantia} AS Agrupar,a.*
                ...    FROM ${formato} a WHERE Usuario='${usuario}') c WHERE Agrupar <> 'X';
                Execute SQL String    ${sql}

                ${sql}    Set Variable        DELETE FROM ${formato} WHERE Usuario='${usuario}'
                Execute SQL String    ${sql}

                ${sql}=    Set Variable    INSERT INTO ${formato} (${columna_din_l},Usuario) SELECT * FROM cuantias_menores_temp WHERE Usuario='${usuario}'
                Execute SQL String    ${sql}

                ${sql}    Set Variable        DROP TEMPORARY TABLE IF EXISTS cuantias_menores_temp
                Execute SQL String    ${sql}
            END
            ${completado}    Set Variable    ${True}
            ${error}    Set Variable     ${None} 
            Disconnect From Database
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}










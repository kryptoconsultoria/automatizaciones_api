*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           Dialogs

# *** Variables ***
# ${config_file}    ../config.yaml
# ${config_file_pdf}    ../config_pdf.yaml


# *** Tasks ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config_file}
#     ${yaml_content_pdf}=    Read File    ${config_file_pdf}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
#     agrupacion   ${config}     ${config_pdf}        


*** Keywords ***
agrupacion
    [Documentation]    Ejecuta un comando SQL para clasificar los datos en su respectivo formato.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${columnas}    Get From Dictionary    ${parametros['config_file']}    formatos
            ${sumatorias}    Get From Dictionary    ${parametros['config_file']}    sumatorias
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            
            ${id_sistema}=    Query    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,IdDepartamento,IdMunicipio,Direccion FROM cliente where Nombre='${cliente}'
            
            ${resultados}=     Query    SELECT Formato FROM puc_exogena a INNER JOIN cliente b ON b.IdCliente=a.Cliente WHERE b.Nombre='${cliente}' AND (formato !='formato_1010') GROUP BY Formato 

            FOR    ${fila}    IN    @{resultados}

                ${formato}            Set Variable    ${fila}[0]
                ${columna_din}         Set Variable    ${columnas}[${formato}]
                ${sumatorias_formato}         Set Variable    ${sumatorias}[${formato}]

                # eliminar la columna de codigo
                ${columna_din}    Replace String    string=${columna_din}    search_for=Codigo,    replace_with=${EMPTY}
                # si el formato tiene concepto añadir la agrupación por concepto
                ${tiene_concepto}    Run Keyword And Return Status    Should Contain    ${columna_din}    Concepto
                ${tiene_numid}    Run Keyword And Return Status    Should Contain    ${columna_din}    NumId
                IF    ${tiene_concepto} and ${tiene_numid}
                    ${columna_din_5}=    Set Variable    Concepto,TipoDoc,NumId
                    ${columna_din}=      Replace String    ${columna_din}    Concepto,TipoDoc,NumId,    ${EMPTY}
                ELSE IF    not ${tiene_concepto} and ${tiene_numid}
                    ${columna_din_5}=    Set Variable    TipoDoc,NumId
                    ${columna_din}=      Replace String    ${columna_din}    TipoDoc,NumId,    ${EMPTY}
                ELSE
                    ${columna_din_5}=    Set Variable    Concepto
                    ${columna_din}=      Set Variable    ${EMPTY}
                END

                ${contador}    Set Variable    1
                ${columna_din_4}    Set Variable    ${EMPTY}
                ${sumatorias_list}    Split String    ${sumatorias_formato}    ,               
                FOR      ${item}    IN    @{sumatorias_list}
                    ${columna_formula}      Set Variable    ABS(SUM(CAST(${item} AS SIGNED))) AS ${item}
                    IF   ${contador} != 1
                        ${columna_din_4}        Set Variable    ${columna_din_4},${columna_formula}
                    ELSE
                        ${columna_din_4}        Set Variable    ${columna_formula}
                    END
                    ${contador}      Evaluate     ${contador}+1
                END

                ${contador}    Set Variable    1
                ${columna_din_6}    Set Variable    ${EMPTY}
                ${columna_din_list}     Split String    ${columna_din}    ,               
                FOR      ${item}    IN    @{columna_din_list}
                    IF    '${item}' != ''
                        ${columna_formula}      Set Variable    ANY_VALUE(${item}) AS ${item}
                        IF   ${contador} != 1
                            ${columna_din_6}        Set Variable    ${columna_din_6},${columna_formula}
                        ELSE
                            ${columna_din_6}        Set Variable    ${columna_formula}
                        END
                    END
                    ${contador}      Evaluate     ${contador}+1
                END

                #========================================================================================================================
                # Agrupar
                ${sql}    Catenate    
                ...    CREATE TEMPORARY TABLE Agrupado AS 
                ...    SELECT ${columna_din_5},${columna_din_6},${columna_din_4}  
                ...    FROM ${formato} WHERE Usuario='${usuario}' GROUP BY ${columna_din_5} 
                ${sql}    Replace String    string=${sql}    search_for=,,    replace_with=,
                Execute SQL String    ${sql}

                ${sql}    Catenate         
                ...    DELETE FROM ${formato} WHERE Usuario='${usuario}'
                Execute SQL String    ${sql}

                ${sql}    Catenate      
                ...    INSERT INTO ${formato} (${columna_din_5},${columna_din},${sumatorias_formato},Usuario) 
                ...    SELECT ${columna_din_5},${columna_din},${sumatorias_formato},'${usuario}'  FROM Agrupado
                ${sql}    Replace String    string=${sql}    search_for=,,    replace_with=,
                Execute SQL String    ${sql}

                ${sql}    Catenate      
                ...    DROP TEMPORARY TABLE Agrupado
                Execute SQL String    ${sql}
            END
            #=========================================================================================================================
            # Agrupar por conceptos vacios para poner valores de Iva
            ${sql}    Catenate
            ...    CREATE TEMPORARY TABLE AgrupadoIva AS 
            ...    SELECT 
            ...    Max(Id),
            ...    Max(Codigo), 
            ...    COALESCE(MAX(CASE WHEN Concepto != '' THEN Concepto ELSE NULL END), '') AS Concepto,
            ...    MAX(TipoDoc) AS TipoDoc,
            ...    NumId,
            ...    MAX(PrimerApellido) AS PrimerApellido,
            ...    MAX(SegundoApellido) AS SegundoApellido,
            ...    MAX(PrimerNombre) AS PrimerNombre,
            ...    MAX(OtrosNombres) AS OtrosNombres,
            ...    MAX(RazonSocial) AS RazonSocial,
            ...    MAX(Direccion) AS Direccion,
            ...    MAX(CodDpto) AS CodDpto,
            ...    MAX(CodMcp) AS CodMcp,
            ...    MAX(PaisResidencia) AS PaisResidencia,
            ...    SUM(PagoDeducible) AS PagoDeducible,
            ...    SUM(PagoNoDeducible) AS PagoNoDeducible,
            ...    SUM(IvaDeducible) AS IvaDeducible,
            ...    SUM(IvaNoDeducible) AS IvaNoDeducible,
            ...    SUM(RetPractRenta) AS RetPractRenta,
            ...    SUM(RetAsumRenta) AS RetAsumRenta,
            ...    SUM(RetPractIvaResp) AS RetPractIvaResp,
            ...    SUM(RetPractIvaNoRes) AS RetPractIvaNoRes
            ...    FROM formato_1001
            ...    WHERE NumId IN (
            ...    SELECT NumId 
            ...    FROM formato_1001 WHERE Usuario='${usuario}'
            ...    GROUP BY NumId
            ...    HAVING SUM(CASE WHEN Concepto = '' THEN 1 ELSE 0 END) > 0
            ...    AND SUM(CASE WHEN Concepto != '' THEN 1 ELSE 0 END) > 0
            ...    )
            ...    GROUP BY NumId;
            Execute SQL String    ${sql}

            ${sql}    Set Variable      DELETE FROM formato_1001 WHERE NumId IN (SELECT NumId FROM AgrupadoIva) AND Usuario='${usuario}';       
            Execute SQL String    ${sql}

            ${sql}    Set Variable     INSERT INTO formato_1001 SELECT *,'${usuario}' FROM AgrupadoIva
            Execute SQL String    ${sql}

            # Borrar duplicados formato_2276
            ${sql}    Catenate     
            ...    DELETE t1 FROM formato_2276 t1
            ...    INNER JOIN formato_2276 t2 
            ...    WHERE t1.id > t2.id AND t1.NumId = t2.NumId
            ...    AND t1.Usuario='${usuario}';
            Execute SQL String    ${sql}

            ${completado}    Set Variable    ${True}
            ${error}    Set Variable     ${None}
            Disconnect From Database
            BREAK
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}
    
*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs

# *** Variables ***
# ${CONFIG_file}    ../config.yaml

# *** Tasks ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config_file}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     clasificacion    ${config}


*** Keywords ***
clasificacion
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

            Execute SQL Script    ${CURDIR}/../sql/limpieza_balances.sql
            Execute SQL Script    ${CURDIR}/../sql/tablas_temporales.sql

            ${sql}    Catenate
            ...    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,
            ...    IdDepartamento,IdMunicipio,Direccion 
            ...    FROM cliente where Nombre='${cliente}'

            ${id_sistema}    Query    ${sql}           

            ${sql}    Catenate
            ...    SELECT *
            ...    FROM puc_exogena a INNER JOIN 
            ...    Cliente b ON b.IdCliente=a.Cliente
            ...    WHERE b.Nombre='${cliente}' 
            ...    AND Formato !='formato_1012' 
            ...    and Formato !='formato_1010' 
            ...    and Formato !='formato_1003'
            ...    order by Formato ASC              

            ${resultados}=    Query     ${sql}     

            FOR    ${fila}    IN    @{resultados}
                ${cuenta_contable}    Set Variable    ${fila}[1]
                ${formato}            Set Variable    ${fila}[3]
                ${concepto}           Set Variable    ${fila}[4]
                ${columna_formato}    Set Variable    ${fila}[5]
                ${calculo}            Set Variable    ${fila}[6]
                ${nit_reporta_1}            Set Variable    ${fila}[7]
                ${cliente}            Set Variable    ${fila}[8]
                ${digitos}            Set Variable    ${fila}[9]

                ${columna_din}         Set Variable    ${columnas}[${formato}]

                ${nit_reporta}        Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][1]',NumId)) AS NumId 
                ${tip_doc_nit_reporta}        Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][2]',TipoDoc)) AS TipoDoc
                ${razon_social_reporta}   Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][3]',RazonSocial)) AS RazonSocial
                ${pais_reporta}   Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][4]',PaisResidencia)) AS PaisResidencia
                ${departamento_reporta}   Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][5]',codDpto)) AS codDpto
                ${ciudad_reporta}   Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][6]',codMcp)) AS codMcp
                ${direccion}   Set Variable    ANY_VALUE(IF('${nit_reporta_1}'='SI','${id_sistema}[0][7]',Direccion)) AS Direccion


                ${columna_din_2}        Replace String    ${columna_din}    NumId    ${nit_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    TipoDoc    ${tip_doc_nit_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    RazonSocial    ${razon_social_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    PaisResidencia    ${pais_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    codDpto    ${departamento_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    codMcp    ${ciudad_reporta}
                ${columna_din_2}        Replace String    ${columna_din_2}    Direccion    ${direccion}
                ${columna_din_2}        Replace String    ${columna_din_2}    Concepto    '${concepto}' AS Concepto
                
                ${columna_din3}        Set Variable    ${columna_din}
                ${columna_din_3}        Replace String    ${columna_din_3}    Concepto    '${concepto}'
                
                #Colocar alias al calculo del puc con el nombre de la columna formato
                ${calculo_alias}    Set Variable    ${EMPTY}
                IF  ',' in '${columna_formato}'
                    ${contador}    Set Variable    0
                    ${calculo_list}     Split String    ${calculo}    ,
                    ${columna_formato_list}     Split String    ${columna_formato}    ,       
                    FOR      ${item1}    IN     @{calculo_list}    
                        ${columna_formula}      Set Variable    ${item1} AS ${columna_formato_list}[${contador}] 
                        IF   ${contador} != 0
                            ${calculo_alias}        Set Variable    ${calculo_alias},${columna_formula}
                        ELSE
                            ${calculo_alias}        Set Variable    ${columna_formula}
                        END
                        ${contador}      Evaluate     ${contador}+1
                    END
                ELSE
                    ${calculo_alias}        Set Variable    ${calculo} AS ${columna_formato}
                END

                #Evaluar si la columna esta vacia
                IF    '${columna_formato}' == '${EMPTY}'
                    ${columna_din}     Set Variable    ${columna_din}
                    ${columna_din_2}    Set Variable    ${columna_din_2}
                ELSE
                    ${columna_din}     Set Variable    ${columna_din},${columna_formato}
                    ${columna_din_2}    Set Variable    ${columna_din_2},${calculo_alias}
                END

                # añádir la columna numid par los formatos que no tengan numid
                ${result}    Run Keyword And Return Status    Should Contain    ${columna_din}    NumId 
                IF    ${result} == ${True}
                    ${condicion_num_id}  Set Variable     ${EMPTY}    
                ELSE
                    ${condicion_num_id}  Set Variable     ANY_VALUE(NumId) AS NumId,
                END

                # Si es formato 1001 exceptuar las cuentas de retencion
                IF  '${formato}' == 'formato_1001'
                    ${condicion_retenciones}        Set Variable    and Codigo LIKE '2365%' or Codigo LIKE '2367%'
                ELSE
                    ${condicion_retenciones}        Set Variable    ${EMPTY}
                END

                ${sql}    Catenate
                ...    INSERT INTO ${formato} (${columna_din},Usuario)
                ...    WITH datos_agg AS (
                ...    SELECT
                ...    ${condicion_num_id}
                ...    ${columna_din_2},'${usuario}' as Usuario
                ...    FROM balances a
                ...    LEFT JOIN (SELECT c.IdTercero FROM exclusion_nits c INNER JOIN Formato k ON k.IdFormato = c.IdFormato 
                ...    AND k.Formato   = '${formato}') ex  ON a.NumId = ex.IdTercero ${condicion_retenciones}
                ...    WHERE a.Codigo LIKE '${cuenta_contable}%'
                ...    AND ex.IdTercero IS NULL AND a.Usuario='${usuario}'
                ...    GROUP BY ${columna_din3}
                ...    ),
                ...    datos_flag AS (
                ...    SELECT d.*,
                ...    SUM(CASE WHEN d.NumId IS NOT NULL AND d.NumId <> '' THEN 1 ELSE 0 END)
                ...    OVER () AS cnt_no_vacios
                ...    FROM datos_agg d
                ...    )
                ...    SELECT ${columna_din},Usuario
                ...    FROM datos_flag
                ...    WHERE
                ...    (cnt_no_vacios > 0 AND NumId IS NOT NULL AND NumId <> '')
                ...    OR
                ...    (cnt_no_vacios = 0 AND (NumId IS NULL OR NumId = ''));

                Execute SQL String    ${sql}      
            END

            # Priorizar el concepto de las cuentas de retencion
            ${sql}    Catenate
            ...    CREATE TEMPORARY TABLE IF NOT EXISTS validacion_terceros_temp AS
            ...    SELECT NumId,
            ...    MAX(IF(Codigo LIKE '6%','SI','NO')) as ValidadorCosto,
            ...    MAX(IF(Codigo LIKE '2365%','SI','NO')) as ValidadorRetencion, 
            ...    MAX(IF(Codigo LIKE '2365%',Concepto,'0')) as Concepto
            ...    FROM (SELECT * FROM formato_1001 
            ...    WHERE Codigo LIKE '6%' or Codigo LIKE '5%'
            ...    or Codigo LIKE '2365%' AND Usuario='${usuario}') a 
            ...    GROUP BY NumId

            Execute SQL String    ${sql}

            ${sql}    Catenate    
            ...    UPDATE formato_1001 a
            ...    INNER JOIN validacion_terceros_temp b ON a.NumId = b.NumId
            ...    SET a.Concepto=b.Concepto
            ...    WHERE (a.Codigo LIKE '2365%'
            ...    OR a.Codigo LIKE '6%' OR a.Codigo LIKE '5%')
            ...    AND b.Concepto != '0' 
            ...    AND Usuario='${usuario}'

            Execute SQL String    ${sql}

            #borrar cuentas asociadas a gasto de personal (cuenta 5 con persona natural en 13)
            #retenciones de personas naturales, los envia al 2276
            IF  '${formato}' == 'formato_1001'
                Pause Execution    message='formato_1001'
                ${sql}    Catenate    
                ...    INSERT INTO formato_2276 (Codigo,EntidadInformante,TipoDoc,
                ...    NumId,PrimerApellido,SegundoApellido,
                ...    PrimerNombre,OtrosNombres
                ...    Direccion,CodDpto,CodMcp,PaisResidencia,Usuario) 
                ...    SELECT Codigo,'Informate general',TipoDoc,NumId,PrimerApellido,SegundoApellido,PrimerNombre,OtrosNombres
                ...    Direccion,CodDpto,CodMcp,PaisResidencia,'${usuario}' 
                ...    FROM formato_1001 WHERE Codigo LIKE '2365%' AND TipoDoc = '13'

                ${sql}    Catenate    
                ...    DELETE FROM formato_1001 WHERE Codigo LIKE '2365%' AND TipoDoc = '13' AND Usuario='${usuario}'
                Execute SQL String    ${sql}
            END
            
            #Formato 1012
            ${sql}=    Catenate
            ...    INSERT INTO formato_1012 (Codigo,Concepto,TipoDoc,NumId,DV,RazonSocial,PaisResidencia,ValorAl3112,Usuario)
            ...    SELECT ANY_VALUE(Codigo),ANY_VALUE(Concepto),ANY_VALUE(TipoDoc),ANY_VALUE(c.NumId),ANY_VALUE(c.DV),
            ...    ANY_VALUE(c.RazonSocial),ANY_VALUE(PaisResidencia),ABS(SUM(CAST(SaldoFinal AS SIGNED))),'${usuario}'
            ...    FROM medios_magneticos.balances a 
            ...    INNER JOIN puc b ON a.Codigo = b.CuentaContable
            ...    INNER JOIN cross_bancos c ON a.Codigo=c.Cuentas AND b.IdCliente=c.IdCliente
            ...    where b.formato='formato_1012' AND b.IdCliente=${id_sistema}[0][1] GROUP BY codigo
            Execute SQL String    ${sql}

            # #Agrupar por cuenta sin importar tercero, solo cuentas donde este registrada la dian y si la sumatoria da 0 descartar
            ${sql}=    Catenate
            ...    WITH cuentas_dian AS (
            ...    select b.*,c.Sumatoria from (SELECT id,Codigo,NumId,SaldoCtasPagar FROM medios_magneticos.formato_1009 where NumId = '800197268') a
            ...    inner join	(SELECT id,Codigo,NumId,SaldoCtasPagar FROM medios_magneticos.formato_1009) b ON a.Codigo=b.Codigo
            ...    inner join  (SELECT ANY_VALUE(Codigo) as Codigo,ANY_VALUE(NumId) as NumId,SUM(CAST(SaldoCtasPagar AS SIGNED)) as Sumatoria FROM medios_magneticos.formato_1009 GROUP BY Codigo) c
            ...    ON  a.Codigo=c.Codigo
            ...    )
            ...    DELETE c FROM formato_1009 AS c INNER JOIN cuentas_dian AS o ON c.Id = o.Id WHERE Sumatoria=0 and Usuario='${usuario}' 
            Execute SQL String    ${sql}

            ${completado}=    Set Variable    ${True}
            ${error}    Set Variable     ${None}
            Disconnect From Database

        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN    ${completado}    ${error}

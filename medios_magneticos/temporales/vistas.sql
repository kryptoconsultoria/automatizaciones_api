DROP VIEW balances;
CREATE VIEW balances AS
SELECT 
		TRIM(
			CONCAT_WS('',
				CASE WHEN TRIM(Grupo) REGEXP '[0-9]' THEN TRIM(Grupo) ELSE '' END,
				CASE WHEN TRIM(Cuenta) REGEXP '[0-9]' THEN TRIM(Cuenta) ELSE '' END,
				CASE WHEN TRIM(SubCuenta) REGEXP '[0-9]' THEN TRIM(SubCuenta) ELSE '' END,
				CASE WHEN TRIM(Auxiliar) REGEXP '[0-9]' THEN TRIM(Auxiliar) ELSE '' END
			)
		) AS Codigo,
        b.TipoPersona AS TipoIdentificacion,
		b.Nit AS NumId,
		DigitoVerificacion AS DV,
        UPPER(REGEXP_REPLACE(IF(c.DireccionComercial IS NULL or '',b.Direccion, c.DireccionComercial),'[^a-zA-Z0-9 ]','')) AS Direccion,
        d.CodDepartamento as CodDpto,
        d.CodigoMunicipio as CodMcp,
        b.Pais as PaisResidencia,
		b.Nombre AS RazonSocial,
		CAST(SaldoAnterior AS float) AS SaldoInicial,
		CAST(Debitos AS float) AS Debito,
		CAST(Creditos AS float) AS Credito,
		CAST(NuevoSaldo AS float) AS SaldoFinal,
		'siigo_pyme' AS SistemaContable
	FROM balance_siigo_pyme as a 
    INNER JOIN terceros_siigo_pyme as b  ON a.Nit=b.Nit
    LEFT JOIN dane_municipios AS d ON TRIM(SUBSTRING_INDEX(Ciudad,'-',1)) = TRIM(d.SiigoPyme)
    LEFT JOIN rues as c ON TRIM(LEADING '0' FROM c.NumeroIdentificacion)=a.NIT
    WHERE a.Nit IS NOT NULL;

Select Pais from terceros_siigo_pyme group by Pais;
select SUBSTRING_INDEX(Ciudad,'-',-1) AS Departamento,SUBSTRING_INDEX(Ciudad,'-',1) AS Ciudad from terceros_siigo_pyme group by Ciudad
UNION ALL
-- Siigo Nube
SELECT 
    CodigoCuentaContable AS Codigo,
    b.TipoIdentificacion AS TipoDoc,
    a.Identificacion AS NumId,
	b.DigitoVerificacion AS DV,
	UPPER(REGEXP_REPLACE(IF(c.DireccionComercial IS NULL or '',b.Direccion, c.DireccionComercial),'[^a-zA-Z0-9 ]','')) AS Direccion,
	d.CodDepartamento as CodDpto,
	d.CodigoMunicipio as CodMcp,
	'' as PaisResidencia,
	NombreCuentaContable AS RazonSocial,
	CAST(SaldoInicial AS float) AS SaldoInicial,
	CAST(MovimientoDebito AS float) AS Debito,
	CAST(MovimientoCredito AS float) AS Credito,
	CAST(SaldoFinal AS float) AS SaldoFinal,
	'siigo_nube' AS SistemaContable
FROM balance_siigo_nube as a 
INNER JOIN terceros_siigo_nube as b  ON a.Identificacion = b.Identificacion
LEFT JOIN rues as c ON  c.NumeroIdentificacion=a.Identificacion
LEFT JOIN dane_municipios AS d ON TRIM(b.Ciudad) = TRIM(d.SiigoNube)
WHERE a.Identificacion IS NOT NULL OR a.Identificacion != ''
UNION ALL
-- alliado
SELECT 
    a.Codigo AS Codigo,
    b.TipoId AS TipoDoc,
    a.Identificacion AS NumId,
    b.DV AS DV,
    UPPER(REGEXP_REPLACE(IFNULL(NULLIF(c.DireccionComercial, ''), b.Direccion), '[^a-zA-Z0-9 ]', '')) AS Direccion,
    d.CodDepartamento AS CodDpto,
    d.CodigoMunicipio AS CodMcp,
    b.Pais AS PaisResidencia,
    a.Tercero AS Tercero,
    a.SaldoInicial AS SaldoInicial,
    a.Debito AS Debito,
    a.Credito AS Credito,
    a.SaldoFinal AS SaldoFinal,
    'alliado' AS SistemaContable
FROM balance_aliaddo AS a
INNER JOIN terceros_aliaddo AS b ON a.Identificacion = b.Identificacion
LEFT JOIN rues AS c ON c.NumeroIdentificacion = a.Identificacion
LEFT JOIN dane_municipios AS d ON TRIM(b.Region) = TRIM(LEADING '0' FROM d.CodigoMunicipio)
WHERE a.Identificacion IS NOT NULL AND a.Identificacion <> ''
UNION ALL
SELECT 
    a.Codigo,
    b.TipoDeIdentificacion AS TipoDoc,
    a.Identificacion AS NumId,
    b.DigitoDeVerificacion AS DV,
    UPPER(REGEXP_REPLACE(IFNULL(NULLIF(c.DireccionComercial, ''), b.Direccion), '[^a-zA-Z0-9 ]', '')) AS Direccion,
    d.CodDepartamento AS CodDpto,
    d.CodigoMunicipio AS CodMcp,
    b.Pais AS PaisResidencia,
    a.NombreDelTercero AS Tercero,
    CAST(a.SaldoAnterior as float) AS SaldoInicial,
    CAST(a.Debito as float) AS Debito,
    CAST(a.Credito as float) AS Credito,
    CAST(a.SaldoFinal as float) AS SaldoFinal,
    'allegra' AS SistemaContable
FROM balance_allegra AS a
INNER JOIN terceros_allegra AS b ON b.Identificacion = a.Identificacion 
LEFT JOIN dane_municipios AS d ON TRIM(b.Municipio) = TRIM(d.Allegra)
LEFT JOIN rues AS c ON c.NumeroIdentificacion = a.Identificacion


CREATE VIEW Clasificacion AS
SELECT a.*,Concepto,Formato FROM balances as a LEFT JOIN puc_exogena as b ON a.Codigo=b.Codigo WHERE a.SistemaContable != 'allegra'






DELIMITER $$

CREATE PROCEDURE Reubicar (
    IN formato VARCHAR(50),
    IN columna VARCHAR(50),
    IN calculo VARCHAR(50),
    IN nit VARCHAR(50),
    IN exclusion VARCHAR(50)
)
BEGIN
    -- Definir variables para construir la consulta dinámica
    SET @insertar = 'INSERT INTO ';
    SET @columnas = '(Concepto,TipoDoc,NumId,RazonSocial,Direccion,CodDpto,CodMcp,CodPais,';
    SET @columnas_2 = ') SELECT b.Concepto, a.TipoDoc, a.NumId, a.RazonSocial, a.Direccion, a.CodDpto, a.CodMcp, a.CodPais,';
    SET @filtro = ' FROM balances AS a INNER JOIN puc_exogena AS b ON a.Codigo = b.Codigoformato_1001 WHERE b.Formato = ';
    
    -- Verificar si los parámetros nit y exclusion están vacíos
    IF nit = '' AND exclusion = '' THEN
        -- Construcción de la consulta dinámica
        SET @query = CONCAT(
            @insertar, ' ', columna, ' ', 
            @columnas, calculo, @columnas_2, 
            @filtro, "'", formato, "'"
        );

        -- Preparar y ejecutar la consulta
        PREPARE stmt FROM @query;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END$$


select * from rues

DELIMITER ;
















SELECT * FROM terceros_siigo_pyme
























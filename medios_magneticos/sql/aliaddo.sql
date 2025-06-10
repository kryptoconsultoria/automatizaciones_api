-- ============================================================= 
-- Limpieza Rues
-- =============================================================
DROP TEMPORARY TABLE IF EXISTS cross_rues;

CREATE TEMPORARY TABLE cross_rues AS
SELECT
    e.IdTipoDoc AS TipoDoc,
    TRIM(LEADING '0' FROM b.NumeroIdentificacion) AS NumId,
    b.RazonSocial AS RazonSocial,
    b.DireccionComercial AS Direccion,
    f.IdDepartamento AS CodDpto,
    f.NombreDepartamento AS Departamento,
    d.IdMunicipio AS CodMcp,
    d.NombreMunicipio AS Municipio,
    '169' AS PaisResidencia
FROM 
    rues b
INNER JOIN 
    cross_dane_municipios d 
    ON d.Homologacion = TRIM(b.Municipio)
INNER JOIN
    cross_dane_departamentos f 
    ON f.Homologacion = TRIM(b.Departamento)
INNER JOIN 
    cross_tipo_doc_dian e 
    ON e.Homologacion = b.TipoIdentificacion;

-- ============================================================= 
-- Clear Siigo Nube
-- =============================================================
ALTER TABLE cross_rues
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE terceros_aliaddo 
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE balance_aliaddo
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Crear tabla de terceros nacionales

select * from terceros_aliaddo;

DROP TEMPORARY TABLE IF EXISTS cross_terceros_aliaddo_nacionales;

CREATE TEMPORARY TABLE cross_terceros_aliaddo_nacionales AS
SELECT 
    e.idTipoDoc AS TipoDoc,
    DV AS DV,
    Identificacion NumId,
    RazonSocial AS RazonSocial,
    Direccion AS Direccion,
    '169' AS PaisResidencia,
    TRIM(LEADING '0' FROM SUBSTRING(Ciudad, -3, 3)) AS CodMcp,
    Region AS CodDpto
FROM 
    terceros_aliaddo AS b
INNER JOIN 
    cross_tipo_doc_dian e 
    ON e.Homologacion = b.TipoId
WHERE
	TRIM(b.Pais) = 'CO';
    

-- Convertir a UTF8
ALTER TABLE cross_terceros_aliaddo_nacionales
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Crear tabla de terceros internacionales
DROP TEMPORARY TABLE IF EXISTS cross_terceros_aliaddo_internacionales;
CREATE TEMPORARY TABLE cross_terceros_aliaddo_internacionales AS
SELECT
    e.IdTipoDoc AS TipoDoc,
    RazonSocial AS RazonSocial,
    Identificacion AS NumId,
    DV AS DV,
    Direccion AS Direccion,
    TRIM(LEADING '0' FROM SUBSTRING(Ciudad, -3, 3)) AS CodMcp,
    Region AS CodDpto,
    Pais,
    f.idPais AS PaisResidencia
FROM 
    terceros_aliaddo b
LEFT JOIN 
    cross_dane_municipios d ON TRIM(d.Homologacion) = TRIM(LEADING '0' FROM SUBSTRING(Ciudad, -3, 3))
    AND TRIM(b.Pais) = 'CO'
LEFT JOIN 
    cross_dane_departamentos g ON TRIM(g.Homologacion) = Region
    AND d.IdDepartamento = g.IdDepartamento AND TRIM(b.Pais) = 'CO'
INNER JOIN 
    cross_tipo_doc_dian e ON e.Homologacion = b.TipoId
LEFT JOIN 
    cross_dian_paises f ON TRIM(b.Pais) = f.Homologacion
WHERE 
    d.IdMunicipio IS NULL 
    AND d.IdDepartamento IS NULL 
    AND (f.idPais != '169' OR f.idPais IS NULL);
    

-- Convertir a UTF8
ALTER TABLE cross_terceros_aliaddo_internacionales
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Crear tabla limpia de terceros
DROP TEMPORARY TABLE IF EXISTS clean_terceros_aliaddo;

CREATE TEMPORARY TABLE clean_terceros_aliaddo AS
SELECT
    IF(c.NumId IS NULL, b.TipoDoc, c.TipoDoc) AS TipoDoc,
	IF(b.NumId REGEXP '^[0-9]+$',calcular_formula_final(IF(c.NumId IS NULL, TRIM(b.NumId), TRIM(c.NumId))),b.DV) AS DV,
    IF(c.NumId IS NULL, b.NumId, c.NumId) AS NumId,
    IF(c.NumId IS NULL, b.RazonSocial, c.RazonSocial) AS RazonSocial,
    IF(c.NumId IS NULL, b.CodMcp, IF(c.PaisResidencia = '169', c.CodMcp, NULL)) AS CodMcp,
    IF(c.NumId IS NULL, b.CodDpto, IF(c.PaisResidencia = '169', c.CodDpto, NULL)) AS CodDpto,
    IF(c.NumId IS NULL, b.Direccion, c.Direccion) AS Direccion,
    IF(c.NumId IS NULL, b.PaisResidencia, c.PaisResidencia) AS PaisResidencia
FROM 
    cross_terceros_aliaddo_nacionales b
LEFT JOIN
    cross_rues c 
    ON c.NumId = b.NumId
UNION ALL
SELECT
    d.TipoDoc AS TipoDoc,
    d.DV AS DV,
    d.NumId AS NumId,
    d.RazonSocial AS RazonSocial,
    d.CodMcp AS CodMcp,
    d.CodDpto AS CodDpto,
    d.Direccion AS Direccion,
    d.PaisResidencia AS PaisResidencia
FROM 
    cross_terceros_aliaddo_internacionales d;

-- ============================================================= 
-- Tabla balances
-- =============================================================
DROP TEMPORARY TABLE IF EXISTS intermedio;

CREATE TEMPORARY TABLE intermedio AS
SELECT 
    Codigo AS Codigo,
    b.TipoDoc AS TipoDoc,
    REGEXP_REPLACE(a.Identificacion, '[^a-zA-Z0-9 ]', '') AS NumId,
    IF (TRIM(b.TipoDoc) IN ('11','12','13','21','22','41'),'',b.DV) AS DV,
    b.Direccion AS Direccion,
    b.CodDpto AS CodDpto,
    b.CodMcp AS CodMcp,
    '' AS Departamento,
    '' AS Municipio,
	b.PaisResidencia AS PaisResidencia,
    '' AS PrimerApellido,
    '' AS SegundoApellido,
    '' AS PrimerNombre,
    '' AS OtrosNombres,
    b.RazonSocial AS RazonSocial,
    CAST(SaldoInicial AS FLOAT) AS SaldoInicial,
    CAST(Debito AS FLOAT) AS Debito,
    CAST(Credito AS FLOAT) AS Credito,
    CAST(SaldoFinal AS FLOAT) AS SaldoFinal
FROM 
    balance_aliaddo AS a
LEFT JOIN 
    clean_terceros_aliaddo AS b 
    ON TRIM(a.Identificacion) = TRIM(b.NumId)
    
    
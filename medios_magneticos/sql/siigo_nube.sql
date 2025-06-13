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

ALTER TABLE terceros_siigo_nube 
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE balance_terceros_siigo_nube 
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

ALTER TABLE balance_siigo_nube  
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Crear tabla de terceros nacionales
DROP TEMPORARY TABLE IF EXISTS cross_terceros_siigo_nube_nacionales;

CREATE TEMPORARY TABLE cross_terceros_siigo_nube_nacionales AS
SELECT 
    e.idTipoDoc AS TipoDoc,
    IF(
        REGEXP_LIKE(b.Identificacion, '-[0-9]$'),
        REPLACE(REGEXP_SUBSTR(b.Identificacion, '-[0-9]$'), '-', ''),
        b.DigitoVerificacion
    ) AS DV,
    IF(
        REGEXP_LIKE(b.Identificacion, '-[0-9]$'),
        REPLACE(REGEXP_REPLACE(b.Identificacion, '-[0-9]$', ''), '.', ''),
        REPLACE(b.Identificacion, '.', '')
    ) AS NumId,
    b.NombreTercero AS RazonSocial,
    b.Direccion AS Direccion,
    b.codPais AS PaisResidencia,
    f.IdMunicipio AS CodMcp,
    f.IdDepartamento AS CodDpto
FROM 
    terceros_siigo_nube AS b
INNER JOIN 
    cross_tipo_doc_dian e 
    ON e.Homologacion = b.TipoDeIdentificacion
INNER JOIN 
    (
        SELECT 
            ANY_VALUE(IdMunicipio) AS IdMunicipio,
            ANY_VALUE(IdDepartamento) AS IdDepartamento,
            NombreMunicipio,
            Homologacion 
        FROM 
            cross_dane_municipios 
        GROUP BY 
            NombreMunicipio,
            Homologacion
    ) f 
    ON f.Homologacion = b.Ciudad 
    AND b.codPais = '169'
WHERE b.Usuario='USUARIO';

-- Convertir a UTF8
ALTER TABLE cross_terceros_siigo_nube_nacionales
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Crear tabla de terceros internacionales
DROP TEMPORARY TABLE IF EXISTS cross_terceros_siigo_nube_internacionales;

CREATE TEMPORARY TABLE cross_terceros_siigo_nube_internacionales AS
SELECT 
    e.idTipoDoc AS TipoDoc,
    IF(
        REGEXP_LIKE(b.Identificacion, '-[0-9]$'),
        REPLACE(REGEXP_SUBSTR(b.Identificacion, '-[0-9]$'), '-', ''),
        b.DigitoVerificacion
    ) AS DV,
    IF(
        REGEXP_LIKE(b.Identificacion, '-[0-9]$'),
        REPLACE(REGEXP_REPLACE(b.Identificacion, '-[0-9]$', ''), '.', ''),
        REPLACE(b.Identificacion, '.', '')
    ) AS NumId,
    b.NombreTercero AS RazonSocial,
    b.Direccion AS Direccion,
    b.codPais AS PaisResidencia,
    f.IdMunicipio AS CodMcp,
    f.IdDepartamento AS CodDpto
FROM 
    terceros_siigo_nube AS b
INNER JOIN 
    cross_tipo_doc_dian e 
    ON e.Homologacion = b.TipoDeIdentificacion
LEFT JOIN 
    cross_dane_municipios f 
    ON f.Homologacion = b.Ciudad 
    AND b.codPais = '169'
WHERE 
    f.IdMunicipio IS NULL
    AND b.Usuario='USUARIO';


-- Convertir a UTF8
ALTER TABLE cross_terceros_siigo_nube_internacionales
CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


-- Crear tabla limpia de terceros
DROP TEMPORARY TABLE IF EXISTS clean_terceros_siigo_nube;

CREATE TEMPORARY TABLE clean_terceros_siigo_nube AS
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
    cross_terceros_siigo_nube_nacionales b
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
    cross_terceros_siigo_nube_internacionales d;

-- ============================================================= 
-- Tabla balances
-- =============================================================
DROP TEMPORARY TABLE IF EXISTS intermedio;

CREATE TEMPORARY TABLE intermedio AS
SELECT 
    CodigoCuentaContable AS Codigo,
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
    a.NombreTercero AS RazonSocial,
    CAST(SaldoInicial AS FLOAT) AS SaldoInicial,
    CAST(Debito AS FLOAT) AS Debito,
    CAST(Credito AS FLOAT) AS Credito,
    CAST(SaldoFinal AS FLOAT) AS SaldoFinal
FROM 
    balance_siigo_nube AS a
LEFT JOIN 
    clean_terceros_siigo_nube AS b 
    ON TRIM(a.Identificacion) = TRIM(b.NumId)
WHERE a.Usuario='USUARIO';
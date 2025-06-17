-- ============================================================= 
-- Limpieza Rues
-- =============================================================
DROP TEMPORARY TABLE IF EXISTS cross_rues;

CREATE TEMPORARY TABLE cross_rues AS
SELECT
    e.IdTipoDoc AS TipoDoc,
    TRIM(TRIM(LEADING '0' FROM b.NumeroIdentificacion)) AS NumId,
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
    cross_dane_municipios d ON TRIM(d.Homologacion) = TRIM(b.Municipio)
INNER JOIN
    cross_dane_departamentos f ON TRIM(f.Homologacion) = TRIM(b.Departamento)
INNER JOIN 
    cross_tipo_doc_dian e ON e.Homologacion = b.TipoIdentificacion;

-- =============================================================
-- Limpiar Siigo pyme
-- =============================================================
ALTER TABLE terceros_siigo_pyme CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;


DROP TEMPORARY TABLE IF EXISTS cross_terceros_siigo_pyme_nacionales;
CREATE TEMPORARY TABLE cross_terceros_siigo_pyme_nacionales AS
SELECT
    DISTINCT
    e.IdTipoDoc AS TipoDoc,
    TRIM(Nombre) AS RazonSocial,
    TRIM(Nit) AS NumId,
    digito_verificacion(Nit) AS DV,
    TRIM(Direccion) AS Direccion,
    g.IdDepartamento AS CodDpto,
    TRIM(SUBSTRING_INDEX(b.Ciudad, '-', -1)) AS Departamento,
    d.IdMunicipio AS CodMcp,
    TRIM(SUBSTRING_INDEX(b.Ciudad, '-', 1)) AS Municipio,
    f.idPais AS PaisResidencia
FROM 
    terceros_siigo_pyme b
LEFT JOIN 
    cross_dane_municipios d ON TRIM(d.Homologacion) = TRIM(SUBSTRING_INDEX(b.Ciudad, '-', 1))
INNER JOIN 
    cross_dane_departamentos g ON TRIM(g.Homologacion) = TRIM(SUBSTRING_INDEX(b.Ciudad, '-', -1))
    AND d.IdDepartamento = g.IdDepartamento AND TRIM(b.Pais) = 'COLOMBIA'
INNER JOIN 
    cross_tipo_doc_dian e ON e.Homologacion = b.TipoPersona
LEFT JOIN 
    cross_dian_paises f ON TRIM(b.Pais) = f.Homologacion
WHERE 
    d.IdMunicipio IS NOT NULL 
    AND d.IdDepartamento IS NOT NULL
    AND  b.Usuario='USUARIO';


ALTER TABLE cross_terceros_siigo_pyme_nacionales CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

DROP TEMPORARY TABLE IF EXISTS cross_terceros_siigo_pyme_internacionales;
CREATE TEMPORARY TABLE cross_terceros_siigo_pyme_internacionales AS
SELECT
    e2.IdTipoDoc AS TipoDoc,
    Nombre AS RazonSocial,
    Nit AS NumId,
    Digito AS DV,
    Direccion AS Direccion,
    g2.IdDepartamento AS CodDpto,
    SUBSTRING_INDEX(b2.Ciudad, '-', -1) AS Departamento,
    d2.IdMunicipio AS CodMcp,
    SUBSTRING_INDEX(b2.Ciudad, '-', 1) AS Municipio,
    f2.idPais AS PaisResidencia
FROM 
    terceros_siigo_pyme b2
LEFT JOIN 
    cross_dane_municipios d2 ON TRIM(d2.Homologacion) = TRIM(SUBSTRING_INDEX(b2.Ciudad, '-', 1)) 
    AND TRIM(b2.Pais) = 'COLOMBIA'
LEFT JOIN 
    cross_dane_departamentos g2 ON TRIM(g2.Homologacion) = TRIM(SUBSTRING_INDEX(b2.Ciudad, '-', -1))
    AND d2.IdDepartamento = g2.IdDepartamento AND TRIM(b2.Pais) = 'COLOMBIA'
INNER JOIN 
    cross_tipo_doc_dian e2 ON e2.Homologacion = b2.TipoPersona
LEFT JOIN 
    cross_dian_paises f2 ON TRIM(b2.Pais) = f2.Homologacion
WHERE 
    d2.IdMunicipio IS NULL 
    AND d2.IdDepartamento IS NULL 
    AND (f2.idPais != '169' OR f2.idPais IS NULL)
    AND  b2.Usuario='USUARIO';
    
    
DROP TEMPORARY TABLE IF EXISTS clean_terceros_siigo_pyme;
CREATE TEMPORARY TABLE clean_terceros_siigo_pyme AS
SELECT
    IF(c.NumId IS NULL, b.TipoDoc, c.TipoDoc) AS TipoDoc,
    IF(c.NumId IS NULL, b.NumId, c.NumId) AS NumId,
    IF(b.NumId REGEXP '^[0-9]+$',calcular_formula_final(IF(c.NumId IS NULL, TRIM(b.NumId), TRIM(c.NumId))),b.DV) AS DV,
    IF(c.NumId IS NULL, b.RazonSocial, c.RazonSocial) AS RazonSocial,
    IF(c.NumId IS NULL, b.Direccion, c.Direccion) AS Direccion,
    IF(c.NumId IS NULL, b.CodDpto, IF(c.PaisResidencia = '169', c.CodDpto, NULL)) AS CodDpto,
    IF(c.NumId IS NULL, b.CodMcp, IF(c.PaisResidencia = '169', c.CodMcp, NULL)) AS CodMcp,
    IF(c.NumId IS NULL, b.Departamento, c.Departamento) AS Departamento,
    IF(c.NumId IS NULL, b.Municipio, c.Municipio) AS Municipio,
    IF(c.NumId IS NULL, b.PaisResidencia, c.PaisResidencia) AS PaisResidencia,
    IF(c.NumId IS NULL, 'Terceros', 'Rues') AS Origen
FROM 
    cross_terceros_siigo_pyme_nacionales b
LEFT JOIN
    cross_rues c ON c.NumId = b.NumId
UNION ALL
SELECT 
    b.TipoDoc,
    b.NumId,
    b.DV,
    b.RazonSocial,
    b.Direccion,
    b.CodDpto,
    b.CodMcp,
    b.Departamento,
    b.Municipio,
    b.PaisResidencia,
    'Terceros'
FROM 
    cross_terceros_siigo_pyme_internacionales b;

-- =============================================================
-- Tabla Balances
-- =============================================================
DROP TEMPORARY TABLE IF EXISTS intermedio;

CREATE TEMPORARY TABLE intermedio AS
SELECT 
    TRIM(
        CONCAT_WS('',
            CASE WHEN TRIM(Grupo) REGEXP '[0-9]' THEN TRIM(Grupo) ELSE '' END,
            CASE WHEN TRIM(Cuenta) REGEXP '[0-9]' THEN TRIM(Cuenta) ELSE '' END,
            CASE WHEN TRIM(SubCuenta) REGEXP '[0-9]' THEN TRIM(SubCuenta) ELSE '' END,
            CASE WHEN TRIM(Auxiliar) REGEXP '[0-9]' THEN TRIM(Auxiliar) ELSE '' END
        )
    ) AS Codigo,
    b.TipoDoc AS TipoDoc,
    a.Nit AS NumId,
    IF (b.TipoDoc IN ('11','12','13','21','22','41'),'',b.dv) AS DV,
    b.Direccion AS Direccion,
    b.CodDpto AS CodDpto,
    b.CodMcp AS CodMcp,
    b.Departamento AS Departamento,
    b.Municipio AS Municipio,
    b.PaisResidencia AS PaisResidencia,
    '' AS PrimerApellido,
    '' AS SegundoApellido,
    '' AS PrimerNombre,
    '' AS OtrosNombres,
    b.RazonSocial AS RazonSocial,
    CAST(SaldoAnterior AS FLOAT) AS SaldoInicial,
    CAST(Debito AS FLOAT) AS Debito,
    CAST(Credito AS FLOAT) AS Credito,
    CAST(NuevoSaldo AS FLOAT) AS SaldoFinal,
    NULL,
    b.Origen AS Origen
FROM 
    balance_siigo_pyme AS a 
LEFT JOIN 
    clean_terceros_siigo_pyme AS b ON TRIM(a.Nit) = TRIM(b.NumId)
WHERE
    a.Usuario='USUARIO';
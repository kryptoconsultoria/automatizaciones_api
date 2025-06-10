-- ============================================================= Vista Tipo Documento Dian
DROP TEMPORARY TABLE IF EXISTS cross_direcciones;
CREATE TEMPORARY TABLE cross_direcciones AS
SELECT
    d.Abreviatura,
    d.Significado,
    jt.alias AS Homologacion
FROM
    direccion AS d
LEFT JOIN
    JSON_TABLE(
        d.Homologacion,
        '$[*]' COLUMNS (
            alias VARCHAR(255) PATH '$'
        )
    ) AS jt
    ON JSON_LENGTH(d.Homologacion) > 0
WHERE jt.alias IS NOT NULL;

-- ============================================================= Vista Tipo Documento Dian
DROP TEMPORARY TABLE IF EXISTS cross_tipo_doc_dian;
CREATE TEMPORARY TABLE cross_tipo_doc_dian AS
SELECT
    d.IdTipoDoc,
    d.Descripcion,
    jt.alias AS Homologacion
FROM
    tipo_doc AS d
LEFT JOIN
    JSON_TABLE(
        d.Homologacion,
        '$[*]' COLUMNS (
            alias VARCHAR(255) PATH '$'
        )
    ) AS jt
    ON JSON_LENGTH(d.Homologacion) > 0;
-- ============================================================= Vista Dane Municipios
DROP TEMPORARY TABLE IF EXISTS cross_dane_municipios;
CREATE TEMPORARY TABLE cross_dane_municipios AS
SELECT
    l.IdMunicipio,
    l.NombreMunicipio,
    mcp_aliases.alias AS Homologacion,
    l.IdDepartamento
FROM
    municipio AS l
LEFT JOIN JSON_TABLE(
    l.Homologacion,
    '$[*]' COLUMNS (
        alias VARCHAR(255) PATH '$'
    )
) AS mcp_aliases
    ON IFNULL(JSON_LENGTH(l.Homologacion), 0) > 0;
    

DROP TEMPORARY TABLE IF EXISTS cross_dane_departamentos;
CREATE TEMPORARY TABLE cross_dane_departamentos AS
SELECT
    l.IdDepartamento,
    l.NombreDepartamento,
    dpto_aliases.alias AS Homologacion
FROM
    departamento AS l
LEFT JOIN JSON_TABLE(
    l.Homologacion,
    '$[*]' COLUMNS (
        alias VARCHAR(255) PATH '$'
    )
) AS dpto_aliases
    ON IFNULL(JSON_LENGTH(l.Homologacion), 0) > 0;

-- ============================================================= Vista Dane paises
DROP TEMPORARY TABLE IF EXISTS cross_dian_paises;
CREATE TEMPORARY TABLE cross_dian_paises AS
SELECT
    d.IdPais,
    d.descripcion,
    jt.alias AS Homologacion
FROM
    pais AS d
LEFT JOIN
    JSON_TABLE(
        d.Homologacion,
        '$[*]' COLUMNS (
            alias VARCHAR(255) PATH '$'
        )
    ) AS jt
    ON JSON_LENGTH(d.Homologacion) > 0;
    
-- ============================================================= Vista Dane paises
DROP TEMPORARY TABLE IF EXISTS cross_dian_paises;
CREATE TEMPORARY TABLE cross_dian_paises AS
SELECT
    d.IdPais,
    d.descripcion,
    jt.alias AS Homologacion
FROM
    pais AS d
LEFT JOIN
    JSON_TABLE(
        d.Homologacion,
        '$[*]' COLUMNS (
            alias VARCHAR(255) PATH '$'
        )
    ) AS jt
    ON JSON_LENGTH(d.Homologacion) > 0;
-- ============================================================= Vista Bancos 1012
DROP TEMPORARY TABLE IF EXISTS cross_bancos;
CREATE TEMPORARY TABLE cross_bancos AS
SELECT
    d.NumId,
    d.RazonSocial,
    d.dv,
    d.CodDpto,
    d.CodMcp,
    d.IdCliente,
    jt.alias AS Cuentas
FROM
    bancos AS d
LEFT JOIN
    JSON_TABLE(
        d.Cuentas,
        '$[*]' COLUMNS (
            alias VARCHAR(255) PATH '$'
        )
    ) AS jt
    ON JSON_LENGTH(d.Cuentas) > 0;
    
ALTER TABLE cross_tipo_doc_dian CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE cross_dian_paises CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE cross_dane_municipios CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE cross_dane_departamentos CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
ALTER TABLE puc MODIFY COLUMN CuentaContable VARCHAR(255) COLLATE utf8mb4_unicode_ci;
ALTER TABLE cross_bancos MODIFY COLUMN Cuentas VARCHAR(255) COLLATE utf8mb4_unicode_ci;
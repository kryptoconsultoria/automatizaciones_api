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
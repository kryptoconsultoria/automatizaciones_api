-- alliado
SELECT
    a.id, 
    a.Codigo,
    e.TipoDocumento AS TipoDoc,
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
INNER JOIN dian_tipo_doc as e ON FIND_IN_SET(e.Aliaddo,b.TipoId)
LEFT JOIN dane_municipios AS d ON TRIM(b.Ciudad) = CONCAT(d.CodDepartamento,d.CodigoMunicipio);
-- allegra
SET SQL_SAFE_UPDATES = 0;
SELECT
    a.id, 
    a.Codigo,
    e.TipoDocumento AS TipoDoc,
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
INNER JOIN dian_tipo_doc as e ON Allegra = b.TipoDeIdentificacion
left JOIN dane_municipios AS d ON CONCAT(TRIM(b.Municipio),'-',TRIM(b.Departamento)) = CONCAT(TRIM(d.AllegraMcp),'-',TRIM(d.AllegraDpto))
LEFT JOIN rues AS c ON c.NumeroIdentificacion = a.Identificacion;

-- avansys
SELECT
    a.id, 
    a.Codigo,
    e.TipoDocumento AS TipoDoc,
    a.Identificacion AS NumId,
    b.DigitoDeVerificacion AS DV,
    UPPER(REGEXP_REPLACE(IFNULL(NULLIF(c.DireccionComercial, ''), b.ContactAddress), '[^a-zA-Z0-9 ]', '')) AS Direccion,
    d.CodDepartamento AS CodDpto,
    d.CodigoMunicipio AS CodMcp,
    b.Pais AS PaisResidencia,
    a.NombreDelTercero AS Tercero,
    CAST(a.SaldoInicial as float) AS SaldoInicial,
    CAST(a.Debito as float) AS Debito,
    CAST(a.Credito as float) AS Credito,
    CAST(a.SaldoFinal as float) AS SaldoFinal,
    'avansys' AS SistemaContable
FROM balance_avansys AS a
INNER JOIN terceros_avansys AS b ON b.Identificacion = CONCAT(b.PrimerApellido,
LEFT JOIN rues AS c ON c.NumeroIdentificacion = a.Referencia
INNER JOIN dian_tipo_doc as e ON FIND_IN_SET(Avansys,b.TipoDeIdentificacion)
left JOIN dane_municipios AS d ON CONCAT(TRIM(b.Municipio),'-',TRIM(b.Departamento)) = CONCAT(TRIM(d.AllegraMcp),'-',TRIM(d.AllegraDpto))




/*DROP TEMPORARY TABLE IF EXISTS terceros_siigo_nube_tmp;
CREATE TEMPORARY TABLE terceros_siigo_nube_tmp AS
SELECT
    a.NombreTercero,
    a.TipoDeIdentificacion,
    a.Identificacion,
    a.DigitoVerificacion,
    a.Direccion,
    b.CodigoCiudadOMunicipio,
    c.Ciudad,
    b.CodigoDepartamento,
    c.EstadoDepartamento,
    c.Pais
FROM
    terceros_siigo_nube a
INNER JOIN (
    SELECT 
        TipoDeDocumento,
        NumeroDeDocumento,
        DigitoVerificacionDV,
        NombresApellidosRazonSocial,
        Direccion,
        CodigoCiudadOMunicipio,
        CodigoDepartamento
    FROM 
        balance_terceros_siigo_nube
    GROUP BY 
        TipoDeDocumento,
        NumeroDeDocumento,
        DigitoVerificacionDV,
        NombresApellidosRazonSocial,
        Direccion,
        CodigoCiudadOMunicipio,
        CodigoDepartamento
) b 
ON b.NumeroDeDocumento = a.Identificacion
INNER JOIN ciudades_siigo_nube c 
ON c.CodigoEstadoDepartamento = b.CodigoDepartamento
AND c.CodigoCiudad = b.CodigoCiudadOMunicipio;*/

















    

    
    
    
    
    
    
    






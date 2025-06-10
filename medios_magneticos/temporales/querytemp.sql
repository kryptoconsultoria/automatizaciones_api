CREATE TEMPORARY TABLE Agrupado AS
SELECT f1.Concepto, f1.TipoDoc, f1.NumId, f1.PrimerApellido,
       f1.SegundoApellido, f1.PrimerNombre, f1.OtrosNombres, f1.RazonSocial, 
       f1.Direccion, f1.CodDpto, f1.CodMcp, f1.PaisResidencia 
FROM formato_1001 f1
JOIN (
    SELECT TipoDoc, NumId, PrimerApellido, SegundoApellido, PrimerNombre, 
           OtrosNombres, RazonSocial, Direccion, CodDpto, CodMcp, PaisResidencia
    FROM formato_1001
    WHERE Concepto = ''
) f2 ON f1.TipoDoc = f2.TipoDoc 
    AND f1.NumId = f2.NumId
    AND f1.PrimerApellido = f2.PrimerApellido
    AND f1.SegundoApellido = f2.SegundoApellido
    AND f1.PrimerNombre = f2.PrimerNombre
    AND f1.OtrosNombres = f2.OtrosNombres
    AND f1.RazonSocial = f2.RazonSocial
    AND f1.Direccion = f2.Direccion
    AND f1.CodDpto = f2.CodDpto
    AND f1.CodMcp = f2.CodMcp
    AND f1.PaisResidencia = f2.PaisResidencia
WHERE f1.Concepto != '';
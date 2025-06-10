SELECT 
  ANY_VALUE(Id) AS Id,
  ANY_VALUE(Concepto) AS Concepto,
  ANY_VALUE(TipoDoc) AS TipoDoc,
  ANY_VALUE(NumId) AS NumId,
  ANY_VALUE(PrimerApellido) AS PrimerApellido,
  ANY_VALUE(SegundoApellido) AS SegundoApellido,
  ANY_VALUE(PrimerNombre) AS PrimerNombre,
  ANY_VALUE(OtrosNombres) AS OtrosNombres,
  ANY_VALUE(RazonSocial) AS RazonSocial,
  ANY_VALUE(Direccion) AS Direccion,
  ANY_VALUE(CodDpto) AS CodDpto,
  ANY_VALUE(CodMcp) AS CodMcp,
  ANY_VALUE(PaisResidencia) AS PaisResidencia,
  SUM(PagoDeducible) AS PagoDeducible,
  SUM(PagoNoDeducible) AS PagoNoDeducible,
  SUM(IvaDeducible) AS IvaDeducible,
  SUM(IvaNoDeducible) AS IvaNoDeducible,
  SUM(RetPractRenta) AS RetPractRenta,
  SUM(RetAsumRenta) AS RetAsumRenta,
  SUM(RetPractIvaResp) AS RetPractIvaResp,
  SUM(RetPractIvaNoRes) AS RetPractIvaNoRes
FROM (
  SELECT 
    IF(
      (RetPractRenta = '' AND RetAsumRenta = '' AND RetPractIvaResp = '' AND RetPractIvaNoRes = '')
      AND (PagoDeducible < 141000 OR PagoNoDeducible < 141000),
      'X',
      ''
    ) AS Agrupar,
    a.*
  FROM automatizaciones.formato_1001 a
) b
WHERE Agrupar = 'X'
GROUP BY Agrupar

UNION ALL

SELECT 
  Id,
  Concepto,
  TipoDoc,
  NumId,
  PrimerApellido,
  SegundoApellido,
  PrimerNombre,
  OtrosNombres,
  RazonSocial,
  Direccion,
  CodDpto,
  CodMcp,
  PaisResidencia,
  PagoDeducible,
  PagoNoDeducible,
  IvaDeducible,
  IvaNoDeducible,
  RetPractRenta,
  RetAsumRenta,
  RetPractIvaResp,
  RetPractIvaNoRes
FROM (
  SELECT 
    IF(
      (RetPractRenta = '' AND RetAsumRenta = '' AND RetPractIvaResp = '' AND RetPractIvaNoRes = '')
      AND (PagoDeducible < 141000 OR PagoNoDeducible < 141000),
      'X',
      ''
    ) AS Agrupar,
    a.*
  FROM automatizaciones.formato_1001 a
) b
WHERE Agrupar <> 'X';
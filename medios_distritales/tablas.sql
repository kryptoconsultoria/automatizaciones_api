CREATE TABLE art_2_compras (
    Vigencia TEXT,
    TipoDoc TEXT,
    NoDeDocumento TEXT,
    NombreORazonSocial TEXT,
    Direccion TEXT,
    Telefono TEXT,
    Email VARCHAR(100),
    Municipio VARCHAR(50),
    Dpto VARCHAR(50),
    ConceptoDePagoOAbonoEnCuenta VARCHAR(100),
    ValorComprasAnual DECIMAL(15,2),
    ValorDevoluciones DECIMAL(15,2),
    Col1 TEXT,
    Col2 TEXT
);

CREATE TABLE art_4_reteica (
    Vigencia VARCHAR(10),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    NombreORazonSocial VARCHAR(100),
    Direccion VARCHAR(150),
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    Municipio VARCHAR(50),
    Dpto VARCHAR(50),
    BaseDeRetencion DECIMAL(50,2),
    Tarifa DECIMAL(50,2),
    MontoReteICA DECIMAL(50,2)
);



CREATE TABLE art_6_suj_reteica (
    Vigencia VARCHAR(50),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    NombreORazonSocial VARCHAR(100),
    Direccion VARCHAR(150),
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    Municipio VARCHAR(50),
    Dpto VARCHAR(50),
    MontoPagoSinIVA DECIMAL(50,2),
    Tarifa DECIMAL(50,2),
    MontoReteICA DECIMAL(50,2)
);


CREATE TABLE art_3_venta_bienes (
    Vigencia VARCHAR(10),
    CodigoCIIU VARCHAR(10),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    NombreORazonSocial VARCHAR(100),
    Direccion VARCHAR(150),
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    Municipio VARCHAR(50),
    Dpto VARCHAR(50),
    ConceptoPagoOAbonoEnCuenta VARCHAR(150),
    ValorTotalIngresoBruto DECIMAL(50,2),
    ValorTotalDevoluciones DECIMAL(50,2)
);


CREATE TABLE art_9_ingresos_rec_terc (
    Vigencia VARCHAR(10),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    RazonSocial VARCHAR(100),
    Direccion VARCHAR(150),
    Telefono VARCHAR(20),
    Email VARCHAR(100),
    Municipio VARCHAR(50),
    Dpto VARCHAR(50),
    PaisDeResidenciaODom VARCHAR(100),
    ConceptoDeIngreso VARCHAR(150),
    ValorDelIngreso DECIMAL(50,2),
    ValorComision DECIMAL(50,2),
    ValorDelIngresoTransferido DECIMAL(50,2)
);


CREATE TABLE art_11_infr_oper (
    LineaMovil VARCHAR(20),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    RazonSocial VARCHAR(100),
    Telefono VARCHAR(20),
    Email VARCHAR(100)
);

CREATE TABLE art_13_ing_fuera_bogota (
    Vigencia VARCHAR(10),
    ValorTotalDelIngresoPorMunicipio DECIMAL(18,2),
    CodigoMunicipioDondeSeObtuvoElIngreso VARCHAR(10),
    CodigoDptoDondeSeObtuvoElIngreso VARCHAR(10),
    CodigoCIIUActividadDesarrollada VARCHAR(10)
);

CREATE TABLE art_14_venta_activos(
    Vigencia VARCHAR(10),
    TipoDoc VARCHAR(20),
    NoDeDocumento VARCHAR(30),
    RazonSocial VARCHAR(100),
    TipoDeActivoFijoVendido VARCHAR(100),
    ValorDelIngreso DECIMAL(18,2)
);

CREATE TABLE art_15_export_bienes (
    Vigencia VARCHAR(10),
    TipoExportacion VARCHAR(50),
    ValorDelIngreso DECIMAL(50,2),
    FechaDeExportacion DATE
);

CREATE TABLE art_1_tabla_2 (
    Anio INT,
    ConceptoIngreso VARCHAR(150),
    ValorActividades DECIMAL(18,2),
    Bimestre VARCHAR(20)
);












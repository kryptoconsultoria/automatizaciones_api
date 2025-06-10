CREATE TABLE balance_worldoffice (
    CodCuentaNivel1 TEXT,
    CodCuentaNivel2 TEXT,
    CodCuentaNivel3 TEXT,
    CodCuentaNivel4 TEXT,
    CodCuentaNivel5 TEXT,
    SaldoInicialDet TEXT,
    TotalDebitosDet TEXT,
    TotalCreditosDet TEXT,
    SaldoFinalDet TEXT,
    CuentaOTercero TEXT,
    SaldoInicialDetDuplicado TEXT,
    TotalDebitosDetDuplicado TEXT,
    TotalCreditosDetDuplicado TEXT,
    SaldoFinalDetDuplicado TEXT
);

CREATE TABLE movimientos_worldoffice (
    Cuenta TEXT,
    Tercero TEXT,
    Fecha TEXT,
    Nota TEXT,
    Cheque TEXT,
    DocNum TEXT,
    Debitos TEXT,
    Creditos TEXT,
    Saldo TEXT
);

CREATE TABLE balance_siigo_pime (
    Grupo TEXT,
    Cuenta TEXT,
    Subcuenta TEXT,
    Auxiliar TEXT,
    Subauxil TEXT,
    NIT TEXT,
    DigitoVerificacion TEXT,
    CentroC TEXT,
    Empty1 TEXT,
    Descripcion TEXT,
    UltimoMov TEXT,
    SaldoAnterior TEXT,
    Debitos TEXT,
    Creditos TEXT,
    NuevoSaldo TEXT
);


DROP TABLE  movimientos_siigo_pyme;
CREATE TABLE movimientos_siigo_pyme (
    CuentaDescripcion TEXT,
    SaldoInicial TEXT,
    Comprobante TEXT,
    Fecha TEXT,
    Nit TEXT,
    Nombre TEXT,
    DescripcionDetalle TEXT,
    InventarioCruceCheque TEXT,
    Base TEXT,
    CcScc TEXT,
    Debitos TEXT,
    Creditos TEXT,
    SaldoMov TEXT
)

CREATE TABLE balance_siigo_nube (
    Nivel TEXT,
    Transaccional TEXT,
    CodigoCuentaContable TEXT,
    NombreCuentaContable TEXT,
    Identificacion TEXT,
    Sucursal TEXT,
    NombreTercero TEXT,
    SaldoInicial TEXT,
    MovimientoDebito TEXT,
    MovimientoCredito TEXT,
    SaldoFinal TEXT
);

CREATE TABLE movimientos_siigo_nube (
    CodigoContable TEXT,
    CuentaContable TEXT,
    Comprobante TEXT,
    Secuencia TEXT,
    FechaElaboracion TEXT,
    Identificacion TEXT,
    Sucursal TEXT,
    NombreTercero TEXT,
    Descripcion TEXT,
    Detalle TEXT,
    CentroCosto TEXT,
    SaldoInicial TEXT,
    Debito TEXT,
    Credito TEXT,
    SaldoMovimiento TEXT,
    SaldoTotalCuenta TEXT
);

CREATE TABLE movimientos_aliaddo (
    Cuenta TEXT,
    Tercero TEXT,
    CentroCosto TEXT,
    Documento TEXT,
    Fecha TEXT,
    Descripcion TEXT,
    Base TEXT,
    SaldoInicial TEXT,
    Debito TEXT,
    Credito TEXT,
    SaldoFinal TEXT
);

CREATE TABLE balance_aliaddo (
    Codigo TEXT,
    Tercero TEXT,
    SaldoInicial TEXT,
    Debito TEXT,
    Credito TEXT,
    SaldoFinal TEXT
);

CREATE TABLE terceros_aliaddo (
    Clasificacion1 TEXT,
    Clasificacion2 TEXT,
    Nombre TEXT,
    Identificacion TEXT,
    Direccion TEXT,
    Telefonos TEXT,
    Ciudad TEXT
);

CREATE TABLE terceros_siigo_nube (
    Id INT AUTO_INCREMENT PRIMARY KEY,
    CuentaContable TEXT,
    DetalleCuenta TEXT,
    Vigencia TEXT,
    TipoDeDocumento TEXT,
    NumeroDeDocumento TEXT,
    DigitoDeVerificacionDV TEXT,
    NombresYApellidosORazonSocial TEXT,
    Direccion TEXT,
    CodigoCiudadOMunicipio TEXT,
    CodigoDepartamento TEXT,
    Telefono TEXT,
    CorreoElectronico TEXT,
    Tarifa TEXT,
    SaldoInicial TEXT,
    Debito TEXT,
    Credito TEXT,
    SaldoFinal TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


CREATE TABLE terceros_siigo_pyme (
    Nit TEXT,
    Sucursal TEXT,
    Nombre TEXT,
    Contacto TEXT,
    Direccion TEXT,
    Pais TEXT,
    Ciudad TEXT,
    Telefono1 TEXT,
    Telefono2 TEXT,
    Telefono3 TEXT,
    Telefono4 TEXT,
    Celular TEXT,
    Fax TEXT,
    Email TEXT,
    Apartado TEXT,
    Cupo TEXT,
    Precio TEXT,
    Califica TEXT,
    Observaciones TEXT,
    Cumple TEXT,
    Vendedor TEXT,
    Tipo TEXT,
    Digito TEXT,
    Clasific TEXT,
    FPago TEXT,
    PerPago TEXT,
    Activida TEXT,
    Descuento TEXT,
    TipoPersona TEXT,
    Declarante TEXT,
    AgenteRetenedor TEXT,
    Autorretenedor TEXT,
    BenRte TEXT,
    AgeRte TEXT,
    Estado TEXT,
    TipSoc TEXT,
    ContactoFacturacion TEXT,
    MailContactoFacturacion TEXT
);

CREATE TABLE DianTipoDoc (
    TipoDocumento VARCHAR(255),
    Descripcion VARCHAR(255),
    SiigoNube VARCHAR(255),
    SiigoPyme VARCHAR(255),
    Allegra VARCHAR(255),
    Aliaddo VARCHAR(255),
    Avansys VARCHAR(255)
);


CREATE TABLE DianTipoDoc (
    Abreviatura VARCHAR(255),
    Descripcion VARCHAR(255),
    SiigoNube VARCHAR(255),
    SiigoPyme VARCHAR(255),
    Allegra VARCHAR(255),
    Aliaddo VARCHAR(255),
    Avansys VARCHAR(255)
);

CREATE TABLE formato_1012 (
    Concepto TEXT,
    TipoDeDocumento TEXT,
    NumeroDeIdentificacion TEXT,
    DV TEXT,
    PrimerApellidoDelInformado TEXT,
    SegundoApellidoDelInformado TEXT,
    PrimerNombreDelInformado TEXT,
    OtrosNombresDelInformado TEXT,
    RazonSocialInformado TEXT,
    PaisDeResidenciaODomicilio TEXT,
    ValorAl3112 TEXT
);

CREATE TABLE balance_allegra (
    Nivel TEXT,
    NumeroDeCuenta TEXT,
    CuentaContable TEXT,
    Debito TEXT,
    Credito TEXT
);


CREATE TABLE movimientos_allegra (
    Asiento TEXT,
    Fecha TEXT,
    Tercero TEXT,
    Identificacion TEXT,
    Documento TEXT,
    Codigo TEXT,
    CuentaContable TEXT,
    Debito TEXT,
    Credito TEXT,
    Estado TEXT
);


CREATE TABLE rues (
    OrgJuridica TEXT,
    Categoria TEXT,
    FechaMatricula TEXT,
    RazonSocial TEXT,
    TipoIdentificacion TEXT,
    NumeroIdentificacion TEXT,
    ActividadEconomica TEXT,
    ActividadEconomica2 TEXT,
    ActividadEconomica3 TEXT,
    ActividadEconomica4 TEXT,
    DescTamanoEmpresa TEXT,
    Departamento TEXT,
    Municipio TEXT,
    DireccionComercial TEXT,
    CorreoComercial TEXT,
    RepLegal TEXT
);

CREATE TABLE terceros_allegra (
    TipoDeContacto TEXT,
    Nombre TEXT,
    SegundoNombre TEXT,
    PrimerApellido TEXT,
    SegundoApellido TEXT,
    TipoDeIdentificacion TEXT,
    Identificacion TEXT,
    DigitoDeVerificacion TEXT,
    TipoDePersona TEXT,
    ResponsabilidadTributaria TEXT,
    Telefono1 TEXT,
    Telefono2 TEXT,
    Celular TEXT,
    Pais TEXT,
    Departamento TEXT,
    Municipio TEXT,
    Direccion TEXT,
    CodigoPostal TEXT,
    CorreoSecundario TEXT,
    Correo TEXT,
    ListaDePrecios TEXT,
    Vendedor TEXT,
    PlazoDePago TEXT,
    CuentasPorCobrar TEXT,
    CuentasPorPagar TEXT,
    LimiteDeCredito TEXT
);


CREATE TABLE dane_municipios (
    CódigoDepartamento TEXT,
    NombreDepartamento TEXT,
    CódigoMunicipio TEXT,
    NombreMunicipio TEXT,
    PersonasenNBI TEXT,
    CabeceraProp TEXT,
    CabeceraCve TEXT,
    RestoProp TEXT,
    RestoCve TEXT,
    TotalProp TEXT,
    TotalCve TEXT
);



CREATE TABLE dane_departamentos (
    CódigoDepartamento TEXT,
    NombreDepartamento TEXT,
    CabeceraProp TEXT,
    CabeceraCve TEXT,
    RestoProp TEXT,
    RestoCve TEXT,
    TotalProp TEXT,
    TotalCve TEXT
);


CREATE TABLE puc_exogena (
    Código TEXT,
    Descripción TEXT,
    Concepto TEXT,
    Formato TEXT,
    NA TEXT,
    Observación TEXT
);

CREATE TABLE nomenclatura (
    Abreviatura TEXT,
    Significado TEXT
);

CREATE TABLE ciudades_siigo_pyme (
    id INT AUTO_INCREMENT PRIMARY KEY,
    Pais TEXT,
    Estado_Departamento TEXT,
    Ciudad TEXT,
    Codigo_Pais TEXT,
    Codigo_Estado_Departamento TEXT,
    Codigo_Ciudad TEXT
);

CREATE TABLE balance_avansys (
    Codigo TEXT,
    Cuenta TEXT,
    Referencia TEXT,
    Tercero TEXT,
    SaldoInicial TEXT,
    Debito TEXT,
    Credito TEXT,
    SaldoFinal TEXT
);


CREATE TABLE terceros_avansys (
    Id TEXT,
    IdentificationDocument TEXT,
    IdNumbers TEXT,
    CheckDigit TEXT,
    PrimerApellido TEXT,
    SegundoApellido TEXT,
    PrimerNombre TEXT,
    OtrosNombres TEXT,
    CommercialName TEXT,
    EmailBounced TEXT,
    ContactAddress TEXT,
    Email TEXT,
    CountryId TEXT,
    Phone TEXT,
    RefTypeId TEXT,
    DocumentTypeId TEXT,
    City TEXT,
    CityId TEXT
);

CREATE TABLE formato_1012 (
    ID INT NOT NULL AUTO_INCREMENT,
    Concepto TEXT,
    TipoDoc TEXT,
    NumId TEXT,
    DV TEXT,
    PrimerApellido TEXT,
    SegundoApellido TEXT,
    PrimerNombre TEXT,
    OtrosNombres TEXT,
    RazonSocialInformado TEXT,
    PaisResidencia TEXT,
    ValorAl3112 TEXT
);

CREATE TABLE dian_paises (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo TEXT NOT NULL,
    descripcion TEXT NOT NULL,
    homologacion TEXT
);

CREATE TABLE exclusion_nits (
    id INT PRIMARY KEY,
    nit TEXT NOT NULL,
    formato TEXT
);

CREATE TABLE terceros_siigo_nube (
	id INT PRIMARY KEY,
    NombreTercero TEXT,
    TipoDeIdentificacion TEXT,
    Identificacion TEXT,
    DigitoVerificacion TEXT,
    Sucursal TEXT,
    TipoDeRegimenIVA TEXT,
    Direccion TEXT,
    Ciudad TEXT,
    Telefono TEXT,
    NombresContacto TEXT,
    Estado TEXT,
    Pais TEXT,
    Departamento TEXT,
    Municipio TEXT
);

CREATE TABLE clientes (
    nombre TEXT,
    nit TEXT,
    dv TEXT,
    direccion TEXT,
    pais TEXT,
    ciudad TEXT,
    municipio TEXT
);

CREATE TABLE sistema (
	id_sistema INT PRIMARY KEY,
    nombre TEXT
);



























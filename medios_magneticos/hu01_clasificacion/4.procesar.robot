*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs


# *** Variables ***
# ${CONFIG}    ../config.yaml
# ${REINTENTOS}    2

# *** Tasks ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     procesar    ${config}


*** Keywords ***
procesar
    [Documentation]    Ejecuta un comando SQL para procesar los formatos y dejarlos en la tabla de balances.
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${REINTENTOS}
        TRY
            ${columnas}    Get From Dictionary    ${parametros['config_file']}    formatos
            ${sumatorias}    Get From Dictionary    ${parametros['config_file']}    sumatorias
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${cliente}   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            ${sql}      Execute SQL Script    ${CURDIR}/../sql/limpieza_balances.sql

            ${id_sistema}=    Query    SELECT IdSistema,IdCliente,IdTipoDoc,Nombre,IdPais,IdDepartamento,IdMunicipio,Direccion FROM cliente where Nombre='${cliente}'

            Execute SQL Script    ${CURDIR}/../sql/tablas_temporales.sql

            IF     ${id_sistema}[0][0] == 1
                Execute SQL Script    ${CURDIR}/../sql/siigo_pyme.sql
            ELSE IF  ${id_sistema}[0][0] == 2
                Execute SQL Script    ${CURDIR}/../sql/siigo_nube.sql
            ELSE IF  ${id_sistema}[0][0] == 3
                Execute SQL Script    ${CURDIR}/../sql/avansys.sql
            ELSE IF  ${id_sistema}[0][0] == 4
                Execute SQL Script    ${CURDIR}/../sql/allegra.sql
            ELSE IF  ${id_sistema}[0][0] == 5
                Execute SQL Script    ${CURDIR}/../sql/aliaddo.sql
            END

            ${sql}=    Catenate
            ...    INSERT INTO Balances 
            ...    (Codigo,TipoDoc,NumId,DV,Direccion,CodDpto,CodMcp,Departamento,Municipio,PaisResidencia,PrimerApellido,SegundoApellido,PrimerNombre,OtrosNombres,RazonSocial,SaldoInicial,Debito,Credito,SaldoFinal,EncontradoDIAN,Usuario)
            ...    SELECT Codigo,TipoDoc,NumId,DV,
            ...    UPPER(Direccion),CodDpto,CodMcp,UPPER(Departamento),UPPER(Municipio),UPPER(PaisResidencia),
            ...    UPPER(PrimerApellido),UPPER(SegundoApellido),UPPER(PrimerNombre),UPPER(OtrosNombres),
            ...    UPPER(RazonSocial),UPPER(SaldoInicial),Debito,Credito,SaldoFinal,NULL,${usuario} FROM intermedio;

            Execute Sql String    ${sql}

            ${sql}=     Catenate    
            ...    SELECT b.Descripcion 
            ...    FROM cliente a 
            ...    INNER JOIN tipo_informante 
            ...    b ON a.IdTipoInformante=b.IdTipoInformate 
            ...    WHERE Nombre='${cliente}'

            ${entidad_informante}=     Query   ${sql}

            ${sql}    Catenate     
            ...    UPDATE balances
            ...    SET EntidadInformante = '${entidad_informante}[0][0]'  

            Execute SQL String    ${sql}

            Disconnect From Database
            ${completado}=    Set Variable    ${True}
            BREAK 
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    [return]    ${completado}

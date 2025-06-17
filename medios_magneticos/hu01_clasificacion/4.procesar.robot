*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
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

            ${exists}=    Run Keyword And Return Status    File Should Exist    ${CURDIR}/../sql/tmp.sql
            Run Keyword If    ${exists}    Remove File    ${CURDIR}/../sql/tmp.sql

            IF     ${id_sistema}[0][0] == 1
                ${content}=    Get File    ${CURDIR}/../sql/siigo_pyme.sql
                ${content2}=   Replace String    ${content}    search_for=USUARIO    replace_with=${usuario}
                Create File    ${CURDIR}/../sql/tmp.sql    ${content2}
            ELSE IF  ${id_sistema}[0][0] == 2
                ${content}=    Get File    ${CURDIR}/../sql/siigo_nube.sql
                ${content2}=   Replace String    ${content}    search_for=USUARIO    replace_with=${usuario}  
                Create File    ${CURDIR}/../sql/tmp.sql    ${content2}
            ELSE IF  ${id_sistema}[0][0] == 3
                ${content}=    Get File    ${CURDIR}/../sql/avansys.sql
                ${content2}=   Replace String    ${content}    search_for=USUARIO    replace_with=${usuario} 
                Create File    ${CURDIR}/../sql/tmp.sql    ${content2}
            ELSE IF  ${id_sistema}[0][0] == 4
                ${content}=    Get File    ${CURDIR}/../sql/allegra.sql
                ${content2}=   Replace String    ${content}    search_for=USUARIO    replace_with=${usuario}  
                Create File    ${CURDIR}/../sql/tmp.sql    ${content2}
            ELSE IF  ${id_sistema}[0][0] == 5
                ${content}=    Get File    ${CURDIR}/../sql/aliaddo.sql
                ${content2}=   Replace String    ${content}    search_for=USUARIO    replace_with=${usuario}  
                Create File    ${CURDIR}/../sql/tmp.sql    ${content2}
            END

            Execute SQL Script    ${CURDIR}/../sql/tmp.sql

            ${sql}=    Catenate
            ...    INSERT INTO Balances 
            ...    (Codigo,TipoDoc,NumId,DV,Direccion,CodDpto,CodMcp,Departamento,Municipio,PaisResidencia,PrimerApellido,SegundoApellido,PrimerNombre,OtrosNombres,RazonSocial,SaldoInicial,Debito,Credito,SaldoFinal,EncontradoDIAN,Usuario,Origen)
            ...    SELECT Codigo,TipoDoc,NumId,DV,
            ...    UPPER(Direccion),CodDpto,CodMcp,UPPER(Departamento),UPPER(Municipio),UPPER(PaisResidencia),
            ...    UPPER(PrimerApellido),UPPER(SegundoApellido),UPPER(PrimerNombre),UPPER(OtrosNombres),
            ...    UPPER(RazonSocial),UPPER(SaldoInicial),Debito,Credito,SaldoFinal,NULL,'${usuario}',Origen FROM intermedio;

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
    RETURN    ${completado}

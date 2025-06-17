*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Resource          ../funciones/arreglar_nombres.robot
Library           RPA.FileSystem



*** Variables ***
${CONFIG_FILE}    ../config.yaml


# *** Tasks ***
# Arreglar nombres
#     [Documentation]    Separar nombres completo
#     ${yaml_content}=    Read File    ${config_file}
#     ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml

#     arreglar_nombres    ${config}


*** Keywords ***
arreglar_nombres
    [Documentation]    Conversion nombres y apellidos
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    ${procesos}    Set Variable    3
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario

            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            
            ${sql}=    Catenate 
            ...    UPDATE balances a
            ...    INNER JOIN persona_natural b ON a.NumId = b.NumId
            ...    SET
            ...    a.PrimerApellido = IF(b.EncontradoDian='NO',a.PrimerApellido,b.PrimerApellido),
            ...    a.SegundoApellido = IF(b.EncontradoDian='NO',a.SegundoApellido,b.SegundoApellido),
            ...    a.PrimerNombre = IF(b.EncontradoDian='NO',a.PrimerNombre,b.PrimerNombre),
            ...    a.OtrosNombres = IF(b.EncontradoDian='NO',a.OtrosNombres,b.OtrosNombres),
            ...    a.EncontradoDian = b.EncontradoDian,
            ...    a.RazonSocial=IF(b.EncontradoDian='NO',a.RazonSocial,'')
            ...    WHERE a.Usuario='${usuario}';
            
            ${sql}=    Catenate    
             ...    SELECT NumId, TipoDoc, RazonSocial,Origen
             ...    FROM automatizaciones.balances a
             ...    WHERE a.TipoDoc IN ('13', '41', '22') 
             ...    AND a.Origen = 'Rues' AND a.Usuario='${usuario}'
             ...    AND PrimerNombre = ''
             ...    GROUP BY NumId, TipoDoc,RazonSocial,Origen;

            ${resultados}=    Query       ${sql}
            
            FOR    ${fila}    IN    @{resultados}
                ${num_id}           Set Variable    ${fila}[0]
                ${tipo_doc}           Set Variable    ${fila}[1]
                ${razon_social}           Set Variable    ${fila}[2]
                ${primer_apellido}    ${segundo_apellido}     ${primer_nombre}    ${segundo_nombre}    ${validar_nombre}    Arreglar nombres apellidos    ${razon_social}

                ${sql}=    Catenate    
                ...    UPDATE balances SET
                ...    PrimerApellido='${primer_apellido}', SegundoApellido='${segundo_apellido}', 
                ...    PrimerNombre='${primer_nombre}', OtrosNombres='${segundo_nombre}',RazonSocial=''
                ...    WHERE NumId='${num_id}'

                Execute SQL String    ${sql}
            END


            ${sql}=    Catenate    
            ...    SELECT NumId, TipoDoc, RazonSocial,Origen
            ...    FROM automatizaciones.balances a
            ...    WHERE a.TipoDoc IN ('13', '41', '22') 
            ...    AND a.Origen = 'Terceros' AND a.Usuario='${usuario}'
            ...    AND PrimerNombre = ''
            ...    GROUP BY NumId, TipoDoc,RazonSocial,Origen;

            ${resultados}=    Query       ${sql}
            
            FOR    ${fila}    IN    @{resultados}
                ${num_id}           Set Variable    ${fila}[0]
                ${tipo_doc}           Set Variable    ${fila}[1]
                ${razon_social}           Set Variable    ${fila}[2]
                ${primer_nombre}    ${segundo_nombre}    ${primer_apellido}    ${segundo_apellido}    ${validar_nombre}    Arreglar nombres apellidos    ${razon_social}

                ${sql}=    Catenate    
                ...    UPDATE balances SET
                ...    PrimerApellido='${primer_apellido}', SegundoApellido='${segundo_apellido}', 
                ...    PrimerNombre='${primer_nombre}', OtrosNombres='${segundo_nombre}',RazonSocial=''
                ...    WHERE NumId='${num_id}'

                Execute SQL String    ${sql}
            END
            
            Disconnect From Database
           ${completado}    Set Variable    ${True}
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}    Set Variable    ${False}
        END
    END
    RETURN    ${completado}
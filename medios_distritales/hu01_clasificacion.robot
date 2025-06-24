*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String

*** Keywords ***
Ordenar Archivos Por Prefijo Numérico
    [Arguments]    ${directorio}
    # 1. Listamos todos los ficheros del directorio
    @{files}=    OperatingSystem.List Files In Directory    ${directorio}
    # 2. Filtramos solo los que tienen formato número.punto.nombre
    @{num_archivos}=    Create List
    FOR    ${f}    IN    @{files}
        ${match}=    Run Keyword And Return Status    Should Match Regexp    ${f}    ^\\d+\\..+
        IF    ${match}
            Append To List    ${num_archivos}    ${f}
        END
    END
    # 3. Ordenamos usando Evaluate para aplicar una función en Python
    ${ordenado}=    Evaluate
    ...    sorted($num_archivos, key=lambda name: int(name.split('.',1)[0]))
    ...    modules=re
    # 4. Devolvemos la lista ordenada
    RETURN    ${ordenado}

HU01 Clasificacion
    [Documentation]    Clasificar movimientos del balance en cada formato de medios exógeno para la DIAN
    [Arguments]    ${config}    ${config_pdf}
    
    &{parametros}=    Create Dictionary    config_file=&{config}    config_pdf=&{config_pdf}
    ${bd_config}       Get From Dictionary    ${config['credenciales']}    base_datos
    ${fecha_actual}    Get Current Date    result_format=%Y-%m-%d %H:%M:%S
    ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario
    #============================================================================================================================================================================ 
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    select * from medios_distritales.estado WHERE IdBot=2 AND HistoriaUsuario='HU01' and Estado IN ('Error','Iniciado') order by fecha desc limit 1
    ${estado_actual}    Query       ${sql}
    ${tam_estado_actual}    Get Length  ${estado_actual}  
    IF  ${tam_estado_actual} == 0
        ${sql}    Catenate
        ...    INSERT INTO estado (Tarea,HistoriaUsuario,Estado,IdBot,Fecha,Usuario) VALUES ('actualizacion_insumos_contabilidad.robot','HU01','Iniciado',2,'${fecha_actual}','${usuario}')
        Execute SQL String    ${sql}
        ${sql}    Catenate    
        ...    select * from medios_distritales.estado WHERE IdBot=2 AND HistoriaUsuario='HU01' and Estado IN ('Error','Iniciado') and Usuario='${usuario}' order by fecha desc limit 1
        ${estado_actual}    Query       ${sql}
    ELSE
        ${sql}    Catenate
        ...    UPDATE medios_distritales.estado SET Estado='Iniciado',HistoriaUsuario='HU01' WHERE IdBot=2 AND idEstado=${estado_actual}[0][0] and Usuario='${usuario}'
        Execute SQL String    ${sql}
    END
    Disconnect From Database
    #============================================================================================================================================================================           
    ${archivos}   Ordenar Archivos Por Prefijo Numérico    ${CURDIR}/hu01_clasificacion
    ${tamano_archivos}    Get Length    item=${archivos}
    ${tamano_archivos}    Evaluate    expression=${tamano_archivos}-1
    ${contador}    Set Variable    0
    ${completado}    Set Variable    ${TRUE}

    FOR    ${robot}    IN    @{archivos}
        # Encontrar la palabra clave
        ${palabra_clave_lista}     Split String    string=${robot}    separator=.
        ${palabra_clave}    Set Variable    ${palabra_clave_lista}[1]       
        # Encontrar siguiente item o siguiente bot
        IF    ${contador} != ${tamano_archivos}     
            ${siguiente_item}    Evaluate    ${contador}+1
            ${siguiente_palabra_clave_lista}     Split String    string=${archivos}[${siguiente_item}]    separator=.
            ${siguiente_palabra_clave}    Set Variable    ${siguiente_palabra_clave_lista}[1]
        ELSE
            ${siguiente_palabra_clave}    Set Variable    	${palabra_clave}    
        END

        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        ${sql}    Catenate    
        ...    Select Count(*) FROM medios_distritales.estado WHERE IdBot=2 AND 
        ...    HistoriaUsuario='HU01' and Tarea='${palabra_clave}.robot' and idEstado=${estado_actual}[0][0] 
        ...    and Estado IN ('Error','Iniciado') and Usuario='${usuario}'

        ${Estado}    Query       ${sql}
        Disconnect From Database  
        IF  '${Estado[0][0]}' == '1' 
            ${completado}     ${error}        Run Keyword    ${palabra_clave}     &{parametros}
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
            IF    ${completado}
                ${sql}    Catenate
                ...    UPDATE medios_distritales.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='${siguiente_palabra_clave}.robot',ErrorDetalle="" WHERE IdBot=2 AND idEstado=${estado_actual}[0][0] and Usuario='${usuario}'
                ${estado}    Set Variable    Iniciado
                ${hu}    Set Variable    HU01
                ${tarea}    Set Variable    ${siguiente_palabra_clave}
                Execute SQL String    ${sql}  
            ELSE
                ${sql}    Catenate
                ...    UPDATE medios_distritales.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='${palabra_clave}.robot',ErrorDetalle="${error}" WHERE IdBot=2 AND idEstado=${estado_actual}[0][0] and Usuario='${usuario}'
                ${estado}    Set Variable    Error
                ${hu}    Set Variable    HU01
                ${tarea}    Set Variable    ${palabra_clave}
                Execute SQL String    ${sql}
                BREAK
            END
        
            IF    ${completado} and '${palabra_clave}' == 'subir_archivos'
                ${sql}    Catenate
                ...    UPDATE medios_distritales.estado SET Estado='Finalizado',HistoriaUsuario='HU01',Tarea='${palabra_clave}.robot' WHERE IdBot=2 AND idEstado=${estado_actual}[0][0] and Usuario='${usuario}'
                ${estado}    Set Variable    Finalizado
                ${hu}    Set Variable    HU01
                ${tarea}    Set Variable    ${palabra_clave}
                Execute SQL String    ${sql}
                BREAK
            END 
            Disconnect From Database
        END
        ${contador}    Evaluate    ${contador}+1
    END
    &{respuesta}=    Create Dictionary    estado=${estado}    hu=${hu}    tarea=${tarea}    error_detalle=${error}
    RETURN   &{respuesta}
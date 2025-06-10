*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Resource          actualizacion_insumos_contabilidad.robot
Resource          actualizacion_insumos_admin.robot
Resource          completar_informacion.robot
Resource          clasificacion.robot
Resource          2276.robot
Resource          1010.robot
Resource          procesar.robot
Resource          1003.robot
Resource          direcciones.robot
Resource          agrupacion.robot
Resource          cuantias_menores.robot
Resource          exportar_excel.robot
Resource          limpiar_ceros.robot
Resource          limpiar_puc.robot
Resource          subir_archivos.robot

*** Keywords ***
HU01 Clasificacion
    [Documentation]    Clasificar movimientos del balance en cada formato de medios exógeno para la DIAN
    [Arguments]    ${config_file}    ${config_file_pdf}        

    ${yaml_content}    Read File    ${config_file}
    ${yaml_content_pdf}    Read File    ${config_file_pdf}
    
    ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    ${config_pdf}      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml

    ${bd_config}       Get From Dictionary    ${config['credenciales']}    base_datos

    ${fecha_actual}    Get Current Date    result_format=%Y-%m-%d %H:%M:%S

    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    select * from automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Estado IN ('Error','Iniciado') order by fecha desc limit 1
    ${estado_actual}    Query       ${sql}
    ${tam_estado_actual}    Get Length  ${estado_actual}  
    IF  ${tam_estado_actual} == 0
        ${sql}    Catenate
        ...    INSERT INTO estado (Tarea,HistoriaUsuario,Estado,IdBot,Fecha) VALUES ('limpiar_puc.robot','HU01','Iniciado',1,'${fecha_actual}')
        Execute SQL String    ${sql}
        ${sql}    Catenate    
        ...    select * from automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Estado IN ('Error','Iniciado') order by fecha desc limit 1
        ${estado_actual}    Query       ${sql}
    ELSE
        ${sql}    Catenate
        ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        Execute SQL String    ${sql}
    END
    Disconnect From Database
    #============================================================================================================================================================================     
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='actualizacion_insumos_admin.robot' and idEstado=${estado_actual}[0][0] and Estado IN ('Error','Iniciado')
    ${Estado}    Query       ${sql}
    Disconnect From Database  
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    actualizacion_insumos_admin  ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='limpiar_puc.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='actualizacion_insumos_admin.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='limpiar_puc.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    limpiar_puc  ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='actualizacion_insumos_contabilidad.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='limpiar_puc.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}   Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='actualizacion_insumos_contabilidad.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')   
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1'   
        ${completado}    actualizacion_insumos_contabilidad  ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='procesar.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='actualizacion_insumos_contabilidad.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='procesar.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')  
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1'      
        ${completado}    procesar   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='completar_informacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='procesar.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='completar_informacion.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')    
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1'     
        ${completado}    completar_informacion    config_file=${config}    par=${False}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='direcciones.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='completar_informacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='direcciones.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')    
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1'   
        ${completado}    direcciones   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='clasificacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='direcciones.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='clasificacion.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')  
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1'   
        ${completado}    clasificacion   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='exportar_excel_1.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='clasificacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='exportar_excel_1.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')   
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}   exportar_excel    ${config}    ${TRUE}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...     UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='1003.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='exportar_excel_1.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END 
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='1003.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')   
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    1003    ${config}    ${config_pdf}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='agrupacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='1003.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='agrupacion.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado') 
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    agrupacion   ${config}    ${config_pdf}  
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='limpiar_ceros.robot' WHERE IdBot=1  AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='agrupacion.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='limpiar_ceros.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')   
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}   limpiar_ceros   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='cuantias_menores.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='limpiar_ceros.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='cuantias_menores.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')    
    ${Estado}    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}   cuantias_menores   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='2276.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='cuantias_menores.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='2276.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado')  
    ${Estado}=    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    2276    ${config}    ${config_pdf}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='1010.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='2276.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='1010.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado') 
    ${Estado}=    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}    1010    ${config}    ${config_pdf}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='exportar_excel_2.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0] 
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='1010.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='exportar_excel_2.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado') 
    ${Estado}=    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}   exportar_excel   ${config}    ${FALSE}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Iniciado',HistoriaUsuario='HU01',Tarea='subir_archivos.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0] 
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='exportar_excel_2.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END
    #============================================================================================================================================================================
    Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
    ${sql}    Catenate    
    ...    Select Count(*) FROM automatizaciones.estado WHERE IdBot=1 AND HistoriaUsuario='HU01' and Tarea='subir_archivos.robot' and idEstado=${estado_actual}[0][0]  and Estado IN ('Error','Iniciado') 
    ${Estado}=    Query       ${sql}
    Disconnect From Database
    IF  '${Estado[0][0]}' == '1' 
        ${completado}   Subir formatos   ${config}
        Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}
        IF    ${completado}
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Finalizado',HistoriaUsuario='HU01',Tarea='subir_archivos.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0] 
        ELSE
            ${sql}    Catenate
            ...    UPDATE automatizaciones.estado SET Estado='Error',HistoriaUsuario='HU01',Tarea='subir_archivos.robot' WHERE IdBot=1 AND idEstado=${estado_actual}[0][0]
        END
        Execute SQL String    ${sql}
        Disconnect From Database
    END

    



    
    











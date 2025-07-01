*** Settings ***
Library     DatabaseLibrary

# *** Variables ***
# ${host}             178.156.139.34
# ${usuario}          mysql
# ${contrasena}       CCdfdyEuDb4UkFUwsTQc1oqqzQaJySpq4Xlf6Xn28ZqPEaIJETdqTxKQEdGPWGQf
# ${nombre_bd}        medios_magneticos
# ${puerto}           25
# ${archivo_csv}      /workspaces/Api_automatizaciones/medios_magneticos/insumos/insumos_siigo_pyme/KRYPTO CONSULTORIA S.A.S/balance_terceros/BALANCE_KRYPTO.csv
# ${nombre_tabla}     balance_siigo_pyme
# ${columnas}         Grupo,Cuenta,Subcuenta,Auxiliar,Subauxil,NIT,Sucursal,DigitoVerificacion,CentroC,Empty1,Descripcion,UltimoMov,SaldoAnterior,Debito,Credito,NuevoSaldo
# ${cabeceras}        7
# ${usuario_sistema}  Felipe

# *** Tasks ***
# Insertar Datos desde CSV a la Base de Datos
#    [Documentation]    Tarea para insertar datos masivamente desde un archivo CSV en una tabla MySQL.
#    Ejecutar Carga Masiva desde CSV    ${nombre_bd}    ${usuario}    ${contrasena}    ${host}    ${puerto}    ${archivo_csv}    ${nombre_tabla}    ${cabeceras}    ${columnas}    ${usuario_sistema}

*** Keywords ***
Ejecutar Carga Masiva desde CSV
    [Documentation]    Ejecuta un comando SQL para cargar datos desde un archivo CSV en la tabla indicada.
    [Arguments]    ${nombre_bd}    ${usuario}    ${contrasena}    ${host}    ${puerto}    ${archivo_csv}    ${nombre_tabla}    ${cabeceras}    ${columnas}    ${usuario_sistema}=${EMPTY}
    Log    Preparando conexión con la base de datos...
    Connect To Database    pymysql    ${nombre_bd}    ${usuario}    ${contrasena}    ${host}    ${puerto}    local_infile=1
    Log    Conexión exitosa con la base de datos: ${nombre_bd}
    Log    Iniciando carga masiva desde el archivo: ${archivo_csv}

     ${cadena_usuario}    Set Variable    ${EMPTY}
    
    IF    '${usuario_sistema}' != '${EMPTY}'
        ${cadena_usuario}    Set Variable    SET Usuario='${usuario_sistema}'
    END
    
    ${comando_sql}    Catenate     
    ...    LOAD DATA LOCAL INFILE '${archivo_csv}' INTO TABLE ${nombre_tabla} 
    ...    CHARACTER SET utf8 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
    ...    LINES TERMINATED BY '\\r\\n' IGNORE ${cabeceras} LINES (${columnas})
    ...    ${cadena_usuario};

    Log    Comando SQL generado: ${comando_sql}

    @{Warnings}=    Query    SHOW WARNINGS
    Log Many    ${Warnings}    

    Execute SQL String    ${comando_sql}
    Log    Carga masiva completada en la tabla: ${nombre_tabla}
    Disconnect From Database
    Log    Conexión cerrada exitosamente.
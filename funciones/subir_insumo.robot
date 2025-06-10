*** Settings ***
Library     DatabaseLibrary

#*** Variables ***
#${host}             127.0.0.1
#${usuario}          root
#${contrasena}       krypto123
#${nombre_bd}        automatizaciones
#${puerto}           3306
#${archivo_csv}      C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/insumos_siigo_pyme/balance_terceros/Balance Dic 2024.csv
#${nombre_tabla}     balance_siigo_pyme
#${columnas}         Grupo,Cuenta,Subcuenta,Auxiliar,Subauxil,NIT,DigitoVerificacion,CentroC,Empty1,Descripcion,UltimoMov,SaldoAnterior,Debitos,Creditos,NuevoSaldo
#${cabeceras}        8
#
#*** Tasks ***
#Insertar Datos desde CSV a la Base de Datos
#    [Documentation]    Tarea para insertar datos masivamente desde un archivo CSV en una tabla MySQL.
#    Ejecutar Carga Masiva desde CSV    ${nombre_bd}    ${usuario}    ${contrasena}    ${host}    ${puerto}    ${archivo_csv}    ${nombre_tabla}    ${cabeceras}    ${columnas}

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
        ${cadena_usuario}    Set Variable    SET  Usuario=${usuario_sistema};
    END
    
    ${comando_sql}    Catenate     
    ...    LOAD DATA LOCAL INFILE '${archivo_csv}' INTO TABLE ${nombre_tabla} 
    ...    CHARACTER SET utf8 FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"' 
    ...    LINES TERMINATED BY '\\r\\n' IGNORE ${cabeceras} LINES (${columnas})
    ...    ${cadena_usuario};

    Log    Comando SQL generado: ${comando_sql}
    Execute SQL String    ${comando_sql}
    Log    Carga masiva completada en la tabla: ${nombre_tabla}
    Disconnect From Database
    Log    Conexión cerrada exitosamente.
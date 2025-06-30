*** Settings ***
Library           RPA.Tables
Library           RPA.Excel.Files
Library           String
Library           ${EXECDIR}/librerias/LibreriaPandas.py

#*** Variables ***
#${archivo_excel}    C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/insumos_siigo_pyme/balance_terceros/Balance Dic 2024.xlsx
#${archivo_csv}      C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/insumos_siigo_pyme/test.csv
#${nombre_hoja}      Hoja1
#${delimitador}      ,                                # Delimitador para el archivo CSV
#${codificacion}     UTF-8                            # Codificación del archivo CSV
#@{indice_columna}   0    1    2    3    4

#*** Tasks ***
#Convertir Excel a CSV
#    [Documentation]    Convierte un archivo Excel a un archivo CSV con delimitador y codificación especificados.
#    Completar Valores Nulos    ${archivo_excel}    ${archivo_csv}    ${nombre_hoja}    ${indice_columna}

*** Keywords ***
Convertir Archivo CSV
    [Documentation]    Convierte una hoja específica de un archivo Excel a un archivo CSV.
    [Arguments]        ${archivo_excel}    ${nombre_hoja}    ${archivo_csv}
    Log                Archivo a Procesar en: ${archivo_excel}
    Open Workbook      ${archivo_excel}    data_only=True
    ${tabla}=          Read Worksheet As Table    header=False    name=${nombre_hoja}
    Close Workbook
    Write Table To CSV      ${tabla}    ${archivo_csv}    encoding=UTF-8    delimiter=,
    Log                Archivo CSV generado en: ${archivo_csv}

Guardar CSV en UTF-8
    [Documentation]    Guarda un archivo CSV existente con codificación UTF-8.
    [Arguments]        ${archivo_origen}    ${archivo_destino}
    ${codificacion}=    Detectar codificacion   ${archivo_origen}
    IF    "${codificacion}" != "utf_8"
        Log                Leyendo archivo CSV: ${archivo_origen}
        ${tabla}=          Read Table From CSV    ${archivo_origen}    encoding=latin1    header=False
        Write Table To CSV      ${tabla}    ${archivo_destino}    encoding=UTF-8
        Log                Archivo convertido y guardado en UTF-8: ${archivo_destino}
    END

Completar Valores Nulos
    [Documentation]    Completar valores nulos con pandas
    [Arguments]        ${archivo_excel}    ${archivo_csv}    ${nombre_hoja}    ${indice_columna}
    Abrir Excel        ${archivo_excel}
    Log                *** Completando datos nulos en columnas específicas ***
    ${result}=         Completar Datos    ${nombre_hoja}    ${archivo_csv}    ${indice_columna}
    Log                ${result}
    Cerrar Excel


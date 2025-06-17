*** Settings ***
Library     RequestsLibrary
Library     ../librerias/LibreriaNombres.py



# *** Tasks ***
# Arreglar nombres
#    [Documentation]    Separar nombres completo
#    Arreglar nombres apellidos    JUAN CARLOS DE LA TORRE PEREZ


*** Keywords ***
Arreglar nombres apellidos
    [Documentation]    Conversion nombres y apellidos
    [Arguments]        ${NombreCompleto}
    ${primer_apellido}    ${segundo_apellido}     ${primer_nombre}    ${segundo_nombre}    ${validar_nombre}   Separar Nombres Completo  ${NombreCompleto}
    RETURN  ${primer_apellido}    ${segundo_apellido}     ${primer_nombre}    ${segundo_nombre}    ${validar_nombre}












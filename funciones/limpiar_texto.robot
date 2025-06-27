*** Settings ***
Library     librerias/ModeloDirecciones.py

# *** Variables ***
# ${texto}    OFIC 45 y KMS 23   
# ${nuevas_palabras}    


# *** Tasks ***
# Correr Modelo Spacy
#     ${nuevas_palabras}    Create List    CL    AV
#     ${entidades}    Extraer Entidades De Direccion    texto=${texto}
#     ${ent_direccion}    Reemplazar Entidades De Direccion     ${texto}    ${entidades}    ${nuevas_palabras}
#     Log    ${ent_direccion}    console=True


*** Keywords ***
Extraer Entidades De Direccion
    [Documentation]    Extraer entidades de direccion
    [Arguments]    ${texto}
    ${entidades}    Extraer Entidades    ${texto}
    Log    ${entidades}
    RETURN    ${entidades}


Reemplazar Entidades De Direccion
    [Documentation]    Extraer entidades de direccion
    [Arguments]    ${texto}    ${entidades}    ${nuevas_palabras}
    ${resultado}    Reemplazar Entidades    ${texto}    ${entidades}    ${nuevas_palabras}
    Log     ${resultado}
    RETURN    ${resultado}

Reemplazar Por Tipo
    [Documentation]    Reemplazar por tipo
    [Arguments]     ${texto}    ${entidades_reemplazar}    ${nueva_palabra}
    ${resultado}    Reemplazar Entidades Por Tipo    ${texto}    ${entidades_reemplazar}    ${nueva_palabra}
    Log    ${resultado}
    RETURN     ${resultado}

Reemplazar Múltiples Tipos
    [Documentation]    Reemplazar multiples tipos
    [Arguments]    ${texto}    ${tipos_reemplazos}   
    ${resultado}    Reemplazar Multiples Tipos Entidades    ${texto}    ${tipos_reemplazos}
    Log    ${resultado}
    RETURN     ${resultado}
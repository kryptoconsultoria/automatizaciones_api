*** Settings ***
Library    RPA.PDF
Library    Collections
Library    String
Library    ${EXECDIR}/librerias/LibreriaPDF.py


#*** Variables ***
#${ARCHIVO_PDF}    C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/pdf_1010/novvai/2.pdf
#${PAGINA}         1

#*** Tasks ***
#Leer y Mostrar Contenido de PDF
#    Leer PDF    ${ARCHIVO_PDF}      ${pagina}

*** Keywords ***
Leer PDF
    [Arguments]    ${archivo_pdf}      ${pagina}
    Open PDF    ${archivo_pdf}
    ${contenido}=    Get Text From PDF      ${archivo_pdf}      pages=${pagina}
    ${claves}=    Get Dictionary Keys    ${contenido}
    ${primera_clave}=    Get From List    ${claves}    0
    ${resultado}=   Get From Dictionary    ${contenido}    ${primera_clave}
    Log      ${resultado}    level=DEBUG
    Close PDF
    RETURN    ${resultado}

Obtener Numero Paginas
    [Arguments]    ${archivo_pdf}
    Open PDF    ${archivo_pdf}
    ${numero_paginas}=    Get Number Of Pages      ${archivo_pdf}
    Log      ${numero_paginas}    level=DEBUG    
    Close PDF
    RETURN    ${numero_paginas}

Leer PDF Plumber
    [Arguments]    ${archivo_pdf}      ${pagina}
    Abrir PDF   ${archivo_pdf}
    ${contenido}=    Extraer Texto    numero_pagina=${pagina}
    Log      ${contenido}        level=DEBUG 
    Cerrar PDF
    RETURN    ${contenido}

Extraer Tablas
    [Arguments]     ${archivo_pdf}      ${pagina}    ${tabla} 
    Abrir PDF   ${archivo_pdf}
    ${contenido}    Extraer Tablas    archivo_pdf=${archivo_pdf}    pagina=${pagina}    tabla=${tabla}
    Log      ${contenido}        level=DEBUG 
    Cerrar PDF
    RETURN    ${contenido}
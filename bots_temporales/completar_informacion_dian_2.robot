*** Settings ***
Library    OperatingSystem
Library    Collections
Library    Dialogs
Library    ../librerias/LibreriaSelenium.py        screenshoot_root_directory=../screenshots/

*** Variables ***
${DIAN_URL}         https://muisca.dian.gov.co/WebRutMuisca/DefConsultaEstadoRUT.faces
${BLANK}    about::blank  

# *** Task ***
# Consulta En Google Chrome
#    [Documentation]    Este caso configura las opciones y el servicio para abrir Internet Explorer.
#    ${resultado}=    Consulta DIAN    1020796665
#    Log    Resultado: ${resultado}      console=True

*** Keywords ***
Consulta DIAN
    [Arguments]    ${rut}
    [Documentation]    Consulta datos en la dian
    ${reintentos}    Set Variable    4
    ${captcha_work}    Set Variable    1
    ${captcha_work}    Convert To Integer   ${captcha_work} 
    FOR    ${i}    IN RANGE    1    ${REINTENTOS}
        TRY
            Log    message=reintento:${i}    console=True
            #==================================================================================================================================================================================
            # IF    ${captcha_work} == 1 and ${i} > 2
            #     Abrir Navegador con Reconexión    url=${DIAN_URL}    headless=False
            # ELSE
            #     Abrir Navegador con Reconexión    url=${DIAN_URL}    headless=True
            # END
            #==================================================================================================================================================================================
            Abrir Navegador con Reconexión   url=${BLANK}    headless=${False}
            Abrir Nueva Pestaña    url=${DIAN_URL}
            #Pause Execution    La ejecución está pausada. Presione OK para continuar.
            #==================================================================================================================================================================================
            # Proceder con la navegación y acciones
            Sleep      8s
            Digitar Texto    xpath=//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit']    text=${rut}
            #Pause Execution    La ejecución está pausada. Presione OK para continuar.
            #==================================================================================================================================================================================
            # IF    ${captcha_work} == 1 and ${i} > 3
            #      Click Captcha
            # END
            #==================================================================================================================================================================================
            Click   xpath=//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:btnBuscar']

            ${count}    Contar Elementos    xpath=//td[text()='No está inscrito en el RUT']
            IF    $count > 0
                ${datos}=   Set Variable    ${None}
                ${completado}=    Set Variable    ${True}
                Cerrar Navegador
                BREAK
            END
            ${captcha_work}    Contar Elementos      xpath=//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:estado']
            Log    message= ${captcha_work}    level=DEBUG
            IF    $captcha_work == 0
                Tomar pantallazo    name=ERROR_${rut}.png
                Sleep      3s
                Cerrar Navegador
                CONTINUE
            END
            ${dv}=    Obtener Texto     xpath=//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:dv']
            ${estado}=    Obtener Texto    xpath=//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:estado']
            ${datos}=    Create List
            Append To List    ${datos}    ${dv}
            Append To List    ${datos}    ${estado}
            IF  '${estado}' != 'REGISTRO ACTIVO'
                Append To List    ${datos}    N/A    N/A    N/A    N/A
            ELSE
                 ${campo2}   Obtener Texto    xpath=(//td[@class='tipoFilaNormalVerde'])[3]
                 ${count}    Contar Elementos   xpath=(//td[@class='tipoFilaNormalVerde'])[6]
                 IF    $count > 0
                     ${campo3}    Obtener Texto    xpath=(//td[@class='tipoFilaNormalVerde'])[4]
                     ${campo4}    Obtener Texto    xpath=(//td[@class='tipoFilaNormalVerde'])[5]
                     ${campo5}    Obtener Texto    xpath=(//td[@class='tipoFilaNormalVerde'])[6]
                 ELSE
                     ${campo3}=    Set Variable    ${EMPTY}
                     ${campo4}=    Set Variable    ${EMPTY}
                     ${campo5}=    Set Variable    ${EMPTY}
                 END
                 Append To List    ${datos}    ${campo2}    ${campo3}    ${campo4}    ${campo5}
            END
            ${completado}=    Set Variable    ${True}
            Tomar pantallazo    name=${rut}.png
            Sleep      3s
            Cerrar Navegador
            BREAK
        EXCEPT     AS    ${error}
            Log     ${error}  console=True
            ${completado}=    Set Variable    ${False}
            Tomar pantallazo    name=ERROR_${rut}.png
            Cerrar Navegador
        END
    END
    RETURN    ${datos}    ${completado}

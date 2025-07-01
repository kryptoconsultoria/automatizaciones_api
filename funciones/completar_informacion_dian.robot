*** Settings ***
Library    SeleniumLibrary   screenshot_root_directory=../screenshots/                                         
Library    OperatingSystem
Library    Collections
Library    Dialogs

*** Variables ***
${URL}              about::blank
${DIAN_URL}         https://muisca.dian.gov.co/WebRutMuisca/DefConsultaEstadoRUT.faces
${BROWSER}          chrome
${USER_AGENT}       Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/96.0.4664.110 Safari/537.36
${OPTIONS}     add_argument("--disable-blink-features=AutomationControlled"); add_experimental_option("useAutomationExtension", False); add_experimental_option("excludeSwitches", ["enable-automation"]);

# *** Task ***
# Consulta En Internet Explorer
#    [Documentation]    Este caso configura las opciones y el servicio para abrir Internet Explorer.
#    ${resultado}=    Consulta DIAN    19310323
#    Log    Resultado: ${resultado}      console=True

*** Keywords ***
Consulta DIAN
    [Arguments]    ${rut}
    [Documentation]    Consulta datos en la dian
    ${reintentos}    Set Variable    5 
    FOR    ${i}    IN RANGE    1    ${REINTENTOS}
        TRY
            #==================================================================================================================================================================================
            Open Browser    ${URL}     ${BROWSER}      options=${OPTIONS}
            Execute JavaScript    window.open('${DIAN_URL}', '_blank');
            # Pause Execution    La ejecución está pausada. Presione OK para continuar.
            #==================================================================================================================================================================================
            # Proceder con la navegación y acciones
            Sleep      18s
            Switch Window       NEW
            Wait Until Element Is Visible    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit
            Input Text    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit    ${rut}
            #Pause Execution    La ejecución está pausada. Presione OK para continuar.
            Click Element    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:btnBuscar
            ${count}=    Get Element Count    xpath=//td[text()='No está inscrito en el RUT']
            Log To Console      ${count}           
            IF    $count > 0
                ${datos}=   Set Variable    ${None}
                ${completado}=    Set Variable    ${True}
                Close Browser
                BREAK
            END

            Wait Until Element Is Visible    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:estado    10s
            ${dv}=    Get Text    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:dv
            ${estado}=    Get Text    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:estado
            ${datos}=    Create List
            Append To List    ${datos}    ${dv}
            Append To List    ${datos}    ${estado}
            IF  '${estado}' != 'REGISTRO ACTIVO'
                Append To List    ${datos}    N/A    N/A    N/A    N/A
            ELSE
                 ${campo2}=   Get Text    xpath=(//td[@class='tipoFilaNormalVerde'])[3]
                 ${count}=    Get Element Count    xpath=(//td[@class='tipoFilaNormalVerde'])[6]
                 IF    $count > 0
                     ${campo3}=    Get Text    xpath=(//td[@class='tipoFilaNormalVerde'])[4]
                     ${campo4}=    Get Text    xpath=(//td[@class='tipoFilaNormalVerde'])[5]
                     ${campo5}=    Get Text    xpath=(//td[@class='tipoFilaNormalVerde'])[6]
                 ELSE
                     ${campo3}=    Set Variable    ${EMPTY}
                     ${campo4}=    Set Variable    ${EMPTY}
                     ${campo5}=    Set Variable    ${EMPTY}
                 END
                 Append To List    ${datos}    ${campo2}    ${campo3}    ${campo4}    ${campo5}
            END
            Close Browser
            ${completado}=    Set Variable    ${True}
            BREAK
        EXCEPT     AS    ${error}
            Log     ${error}  console=True
            ${completado}=    Set Variable    ${False}
            Close Browser
        END
    END
    RETURN    ${datos}    ${completado}

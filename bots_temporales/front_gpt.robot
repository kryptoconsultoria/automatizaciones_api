*** Settings ***
Library    SeleniumLibrary   screenshot_root_directory=../screenshots/                                         
Library    OperatingSystem
Library    Collections
Library    Dialogs

*** Variables ***
${URL}              about::blank
${URL_GPT}         https://chatgpt.com/
${BROWSER}          chrome
${REINTENTOS}       4
${USER_AGENT}       Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) HeadlessChrome/96.0.4664.110 Safari/537.36
${OPTIONS}     add_argument("--disable-blink-features=AutomationControlled"); add_experimental_option("useAutomationExtension", False); add_experimental_option("excludeSwitches", ["enable-automation"]);



*** Tasks ***
Consulta En Chrome
    [Documentation]    Este caso configura las opciones y el servicio para abrir Internet Explorer.
    Consulta GPT   19310323




*** Keywords ***
Consulta GPT
    [Arguments]    ${rut}
    [Documentation]    Consulta datos en la dian
    FOR    ${i}    IN RANGE    1    ${REINTENTOS}
        TRY
            Open Browser    ${URL_GPT}     ${BROWSER}      options=${OPTIONS}
            Wait Until Element Is Visible    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit
            ${count}=    Get Element Count    xpath=//button[div[contains(text(),'Iniciar sesión')]]
            IF    $count > 0
                Click Element    xpath=//button[div[contains(text(),'Iniciar sesión')]]
                #Input Text    id=vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit    ${rut}
            END
            Pause Execution    Ejecucion Pausada
            BREAK
         EXCEPT     AS    ${error}
            Log     ${error}  console=True
            ${completado}=    Set Variable    ${False}
            Close Browser
        END
    END
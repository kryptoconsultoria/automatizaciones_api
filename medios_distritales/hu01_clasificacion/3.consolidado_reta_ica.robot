*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           String
Library           Dialogs


*** Keywords ***
consolidado_ica
    [Documentation]    extraccion de consolidado ICA
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN   ${completado}




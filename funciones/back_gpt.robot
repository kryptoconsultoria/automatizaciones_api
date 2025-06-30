*** Settings ***
Library           ${EXECDIR}/librerias/LibreriaGPT.py
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Collections

*** Variables ***
${clave_api}        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
${id_thread}           gpt-4 
${id_assistente}         Hola asasasas
${archivo_pdf}


*** Tasks ***
Hacer Prompt en GPT
   [Documentation]    Hacer consulta a chatgpt
   Hacer Consulta a GPT    ${clave_api}    ${id_thread}    ${id_assistente}      ${archivo_pdf}


*** Keywords ***
Hacer Consulta a GPT
    [Documentation]    Hacer Prompt a chatgpt 
    [Arguments]       ${clave_api}    ${id_hilo}    ${id_asistente}    ${archivo_pdf}
    Log        Consulta a hacer en chatgpt 
    Autenticar ChatGPT     ${clave_api}
    Actualizar hilo      id_hilo=${id_hilo}    archivo_pdf=${archivo_pdf}
    ${Resultado}    Correr hilo    id_thread=${id_hilo}    assistant_id=${id_asistente}
    Log        Resultado de la consulta ${Resultado}
    RETURN     ${Resultado}









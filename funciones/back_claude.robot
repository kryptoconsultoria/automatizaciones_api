*** Settings ***
Library     RequestsLibrary
Library     librerias/LibreriaClaude.py

# *** Variables ***
# ${CLAVE_API}        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
# ${PROMPT}           You are an excellent colombian accountant with high capabilities of system programming responsible for preparing the magnetic media to present information to the DIAN.
# ...                 You need to review PDF files containing third-party information related to withholding tax, which must be reported in the DIAN's required format 1003 for the presentation of magnetic media.
# ...                 In this format, one of the items to be reported is the withheld amount. To extract this information from the PDF database, you should consider the following.
# ...                 Extract only the required data.
# ...                 Respond only with the required output data, avoiding any additional text.
# ...                 Only provide the data that appears in the PDF.
# ...                 If no data is available, assign the value 0.
# ...                 "1302": "0",
# ...                 "1304": "in this field, extract the withholding value associated with 'Honorarios', 'Retención en la fuente', 'Retefuente', or any related terms",
# ...                 "1303": "in this field, extract the withholding value for services, if it appears",
# ...                 "1305": "if there is a second occurrence of withholding for 'Honorarios' or related terms, place it here",
# ...                 "1306": "In this field, extract the withholding value if 'rendimientos financieros' or related terms are mentioned",
# ...                 "1307": "0",
# ...                 "1308": "in this field, extract the withholding value for 'Otros Ingresos Tributarios' or if the term 'software' appears",
# ...                 "1309": "0",
# ...                 "1310": "0",
# ...                 "1311: "0",
# ...                 "1312": "0",
# ...                 "1313": "0",
# ...                 "NIT": "if you can see the nit extract the nit in this field",
# ...                 "1301": "0",
# ...                 "1314": "0",
# ...                 "1320": "0"
# ${MODELO}          claude-3-5-sonnet-20241022
# ${PDF}             C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/pdf_1003/5. RTE FUENTE BOX.pdf
# ${CAMPO}           1302

# *** Tasks ***
# Consulta Claude
#     ${Base64}     Pasar a base 64    ${PDF}
#     ${cadena_json}    Prompt Claude    ${CLAVE_API}    ${MODELO}    ${PROMPT}    ${Base64}

*** Keywords ***
Convertir a base 64
    [Documentation]    Conversión de PDF a base64
    [Arguments]        ${PDF}    ${Password}    
    ${resultado}       Pasar a base 64    ruta_pdf=${PDF}    pass_pdf=${Password} 
    RETURN           ${resultado}

Prompt Claude
    [Documentation]    Consulta de PDF para retornar resultados en JSON
    [Arguments]        ${CLAVE_API}    ${MODELO}    ${PROMPT}    ${PDF}
    Autenticar         api_key=${CLAVE_API}
    ${cadena_json}       Consulta Claude    modelo=${MODELO}    pdf_base_64=${PDF}    prompt=${PROMPT}
    Log     cadena json:${cadena_json}
    RETURN           ${cadena_json}




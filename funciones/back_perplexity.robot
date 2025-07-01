*** Settings ***
Library           ${EXECDIR}/librerias/LibreriaPerplexity.py
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Collections

# *** Variables ***
# ${CLAVE_API}        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
# ${INSTRUCCIONES}     with the  provided name of a business CORPRENAL SA and optionally the city of its headquarters GUAYAQUIL, search for and retrieve the full name and the headquarter address, including the city and country. 
# ...    If applicable, also retrieve the address and city of any subsidiary or branch of the company located in Colombia.
# ...    # Steps
# ...    1. Identify the full name and headquarter address of the business.
# ...    2. Determine the country and city of the headquarter address.
# ...    3. If applicable, locate the address and city of a Colombian branch or subsidiary.
# ...    # Output Items
# ...    Please output only a JSON object containing the following fields:
# ...    "Headquarter_Address": "Address of the business headquarter, only get the address",
# ...    "Headquarter_Country": "Country of the business headquarter, only get the Country",
# ...    "Headquarter_City": "City of the business headquarter, only get the City",
# ...    "Colombia_Address": "Address of the business branch or subsidiary in Colombia, only get the address",
# ...    "Colombia_City": "City of the business branch or subsidiary in Colombia, only get the City"
# ...    # Notes
# ...    - Ensure accuracy in the name and address details.
# ...    - If there is no branch or subsidiary in Colombia, leave the respective fields empty.
# ...    - When city information for the headquarter is provided in the prompt, cross-verify with the search results.
# ${PROMPT}    You are an advanced search engine designed to retrieve detailed business information.
# ${MODELO}    sonar-pro


# *** Tasks ***
# Hacer Prompt en Perplexity
#    [Documentation]    Hacer consulta a perplexity
#    Prompt Perplexity    ${clave_api}    ${modelo}    ${prompt}    ${instrucciones}


*** Keywords ***
Prompt Perplexity
   [Documentation]    Hacer Prompt a perplexity
   [Arguments]       ${clave_api}    ${modelo}    ${prompt}    ${instrucciones}
   Log        Consulta a hacer en chatgpt 
   Autenticar Perplexity     ${clave_api}
   ${Resultado}    Consultar PerPlexity    model=${modelo}    prompt=${prompt}    instructions=${instrucciones}
   Log        Resultado de la consulta ${Resultado}    console=True
   RETURN     ${Resultado}










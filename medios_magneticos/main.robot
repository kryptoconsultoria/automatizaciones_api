*** Settings ***
Library     SeleniumLibrary
Library     RPA.Tasks
Library     Collections
Library     dotenv
Resource    hu01_clasificacion.robot


*** Variables ***
${CONFIG_FILE}    ${CURDIR}/config.yaml
${CONFIG_FILE_PDF}    ${CURDIR}/config_pdf.yaml
${CLIENTE}    Krypto_consultoria 
${USUARIO}    admin
${CHAT_GPT_TOKEN}    Get Environment Variable    CHAT_GPT_TOKEN
${CLAUDE_TOKEN}    Get Environment Variable    CLAUDE_TOKEN
${CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS}    Get Environment Variable    CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS
${CONTRASENA_BD_MEDIOS_MAGNETICOS}    Get Environment Variable    CONTRASENA_BD_MEDIOS_MAGNETICOS
${PERPLEXITY_TOKEN}    Get Environment Variable    PERPLEXITY_TOKEN
${SECRET_ID_MEDIOS_MAGNETICOS}    Get Environment Variable    SECRET_ID_MEDIOS_MAGNETICOS


*** Tasks ***
Medios magneticos
    [Documentation]    Clasifica formatos de la Dian y saca medios magneticos
    # Leer y cargar la configuración desde el archivo YAML
    ${yaml_content}=    Read File    ${config_file}
    ${yaml_content_pdf}=    Read File    ${config_file_pdf}


    ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml

    # Enviar al diccionario los datos capturados en fast api
    Set To Dictionary    ${config['credenciales']}    cliente      ${CLIENTE}                        
    Set To Dictionary    ${config['credenciales']}    usuario      ${USUARIO}

    #Obtener por medio de variables de entorno tokens de acceso chat_gpt
    Set To Dictionary    ${config['credenciales']['chat_gpt']}    token      ${CHAT_GPT_TOKEN}

    #Obtener por medio de variables de entorno tokens de acceso claude                        
    Set To Dictionary    ${config['credenciales']['claude']}    token      ${CLAUDE_TOKEN}

    #Obtener por medio de variables de entorno tokens de acceso office
    Set To Dictionary    ${config['credenciales']['sharepoint']}    id_cliente      ${CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS}
    Set To Dictionary    ${config['credenciales']['sharepoint']}    secreto_cliente      ${SECRET_ID_MEDIOS_MAGNETICOS}

    #Obtener por medio de variables de entorno tokens de acceso perplexity
    Set To Dictionary    ${config['credenciales']['perplexity']}    token      ${PERPLEXITY_TOKEN}

    #Crear json de salida
    ${ruta_json}    Set Variable    ${CURDIR}/../medios_magneticos/salida.json
    ${json_existe}    Does file exist      ${ruta_json}
    
    IF    ${json_existe}
        OperatingSystem.Remove File    ${ruta_json}
    END

    &{respuesta}    HU01 Clasificacion    ${config}     ${config_pdf}

    ${respuesta_json}=      Convert JSON to string    ${respuesta}

    OperatingSystem.Create File    ${ruta_json}    content=${respuesta_json}
        

    
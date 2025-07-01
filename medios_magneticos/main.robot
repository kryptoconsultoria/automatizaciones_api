*** Settings ***
Library     SeleniumLibrary
Library     RPA.Tasks
Library     Collections
Resource    hu01_clasificacion.robot
Variables   ${EXECDIR}/env_vars.py


*** Variables ***
${CONFIG_FILE}    ${CURDIR}/config.yaml
${CONFIG_FILE_PDF}    ${CURDIR}/config_pdf.yaml
${CLIENTE}    Krypto_consultoria 
${USUARIO}    admin

*** Tasks ***
Medios magneticos
    [Documentation]    Clasifica formatos de la Dian y saca medios magneticos
    # Leer y cargar la configuración desde el archivo YAML
    ${yaml_content}=    Read File    ${config_file}
    ${yaml_content_pdf}=    Read File    ${config_file_pdf}


    ${config}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    ${config_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml

    #Crear json de salida
    ${ruta_json}    Set Variable    ${CURDIR}/../medios_magneticos/salida.json
    ${json_existe}    Does file exist      ${ruta_json}
    
    IF    ${json_existe}
        OperatingSystem.Remove File    ${ruta_json}
    END

    # Enviar al diccionario los datos capturados en fast api
    Set To Dictionary    ${config['credenciales']}    cliente      ${CLIENTE}                        
    Set To Dictionary    ${config['credenciales']}    usuario      ${USUARIO}

    #Obtener por medio de variables de entorno tokens de acceso office
    Set To Dictionary    ${config['credenciales']['sharepoint']}    id_cliente      ${CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS}
    Set To Dictionary    ${config['credenciales']['sharepoint']}    secreto_cliente      ${SECRET_ID_MEDIOS_MAGNETICOS}

    #Obtener por medio de variables de entorno credenciales de la base de datos
    Set To Dictionary    ${config['credenciales']['base_datos']}    contrasena      ${CONTRASENA_BD_MEDIOS_MAGNETICOS}

     # Asegurar que 'perplexity' sea un diccionario
    ${has}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${config['credenciales']}    perplexity
    ${is_none}=    Evaluate    ${config['credenciales'].get('perplexity', None)} is None
    IF    not ${has} or ${is_none}
        &{empty}=    Create Dictionary
        Set To Dictionary    ${config['credenciales']}    perplexity=${empty}
    END
    Set To Dictionary    ${config['credenciales']['perplexity']}    token=${PERPLEXITY_TOKEN}

    # Repetir para 'chat_gpt'
    ${has}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${config['credenciales']}    chat_gpt
    ${is_none}=    Evaluate    ${config['credenciales'].get('chat_gpt', None)} is None
    IF    not ${has} or ${is_none}
        &{empty}=    Create Dictionary
        Set To Dictionary    ${config['credenciales']}    chat_gpt=${empty}
    END
    Set To Dictionary    ${config['credenciales']['chat_gpt']}    token=${CHAT_GPT_TOKEN}

    # Repetir para 'claude'
    ${has}=    Run Keyword And Return Status    Dictionary Should Contain Key    ${config['credenciales']}    claude
    ${is_none}=    Evaluate    ${config['credenciales'].get('claude', None)} is None
    IF    not ${has} or ${is_none}
        &{empty}=    Create Dictionary
        Set To Dictionary    ${config['credenciales']}    claude=${empty}
    END
    Set To Dictionary    ${config['credenciales']['claude']}    token=${CLAUDE_TOKEN}

    #Ejecucion de HU01 Clasificacion
    &{respuesta}    HU01 Clasificacion    ${config}     ${config_pdf}
    ${respuesta_json}=      Convert JSON to string    ${respuesta}

    OperatingSystem.Create File    ${ruta_json}    content=${respuesta_json}
        

    
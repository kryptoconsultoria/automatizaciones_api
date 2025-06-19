*** Settings ***
Library     SeleniumLibrary
Library     RPA.Tasks
Library     Collections
Library     OperatingSystem
Library     RPA.FileSystem
Resource    hu01_clasificacion.robot

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

    Set To Dictionary    ${config['credenciales']}    cliente      ${CLIENTE}                        
    Set To Dictionary    ${config['credenciales']}    usuario      ${USUARIO}

    HU01 Clasificacion    ${config}     ${config_pdf}
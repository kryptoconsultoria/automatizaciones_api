*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Library           Dialogs
Resource          ${EXECDIR}/funciones/leer_pdf.robot
Resource          ${EXECDIR}/funciones/descargar_onedrive.robot
Variables         ${EXECDIR}/env_vars.py



*** Variables ***
${config_file}    ${CURDIR}/../config.yaml
${config_file_pdf}    ${CURDIR}/../config_pdf.yaml
${REGEX_EXP}    \\b[A-Za-z]{2} ((?:0|\\d{1,3}(?:,\\d{3})+))\\b
${REGEX_BIM}    \\b((?:[1-6]|X)(?:\\s+(?:[1-6]|X)){6})\\b
${REGEX_MONTO}  (?:\\s+(?:[1-6]|X)){6})\\b

  

*** Tasks ***
LLenar Rete Ica
    [Documentation]    Clasifica formatos de la Dian
    ${yaml_content}    Read File    ${config_file}
    ${yaml_content_pdf}    Read File    ${config_file_pdf}
    ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
    ${config_pdf}      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml
    # Enviar al diccionario los datos capturados en fast api
    Set To Dictionary    ${config['credenciales']}    cliente      KRYPTO CONSULTORIA S.A.S                        
    Set To Dictionary    ${config['credenciales']}    usuario      felipe
    
    # Obtener por medio de variables de entorno tokens de acceso office
    Set To Dictionary    ${config['credenciales']['sharepoint']}    id_cliente      ${CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS}
    Set To Dictionary    ${config['credenciales']['sharepoint']}    secreto_cliente      ${SECRET_ID_MEDIOS_MAGNETICOS}

    # Obtener por medio de variables de entorno credenciales de la base de datos
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
    
    &{parametros}=    Create Dictionary    config_file=&{config}    config_pdf=&{config_pdf}
    consolidado_ica    &{parametros}

    

*** Keywords ***
consolidado_ica
    [Documentation]    extraccion de consolidado ICA
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    	2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            # Obtener las rutas locales y la configuración de la base de datos
            ${ica}    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   ica
            ${bd_config}       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
            ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


            # Obtener cliente a procesar
            ${cliente}=   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente

            #Conexion a sharepoint
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            # Conectar a la base de datos
            Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}

            ${sql}     Catenate  
            ...    TRUNCATE TABLE consolidado_ica
            Execute Sql String   ${sql}

            #==================================================================================
            # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
            ${ruta_completa}    Replace String    ${CURDIR}/../${ica["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
            ${ruta_nube}    Replace String    ${ica["ruta_nube"]}    CLIENTE   ${cliente}


            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_insumos}    Set Variable    ${CURDIR}/../insumos
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_insumos}
            IF    not ${existe}
                Create Directory    ${ruta_insumos}
            END
            
            # Crear carpeta si no xiste insumos sistema contabilidad
            ${ruta_ica}    Set Variable    ${CURDIR}/../insumos/ica
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_ica}
            IF    not ${existe}
                Create Directory    ${ruta_ica}
            END

            # Crear carpeta si no existe cliente
            ${existe}=    Run Keyword And Return Status    Directory Should Exist    ${ruta_completa}
            IF    not ${existe}
                Create Directory    ${ruta_completa}
            END

            #Borrar archivos de cada carpeta
            Remove Files    ${ruta_completa}/*


            #Enlistar archivo de sharepoint
            ${estado}    ${archivos}=     Listar archivos    refresh_token=${token_refresco}     secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}   nombre_del_sitio=${sharepoint['nombre_sitio']}    ruta_carpeta=${ruta_nube}    id_cliente=${sharepoint['id_cliente']}       
            IF    '${estado}' == 'No encontrado'
                ${completado}=    Set Variable    ${True}
                RETURN    ${completado}
            END
            
            FOR    ${archivo}  IN   @{archivos}
                #Descargar archivo de sharepoint
                ${archivo}    Convert To String    item=${archivo}
                ${archivo}    Replace String    search_for=File:    string=${archivo}    replace_with=${empty}
                ${archivo}    Strip String    string=${archivo}
                ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${ruta_completa}
                IF  '${estado_descarga}' == 'Fallido'
                    ${completado}=    Set Variable    ${False}
                    RETURN    ${completado}
                ELSE IF    '${estado_descarga}' == 'No encontrado'
                    CONTINUE
                END
            END
             #==================================================================================
            ${archivos}=    OperatingSystem.List Files In Directory    ${ruta_completa}

            FOR    ${file}    IN    @{archivos}
                ${archivo}    Set Variable         ${ruta_completa}${file}

                #Obtener cantidad de páginas
                ${numero_paginas}     Obtener Numero Paginas    ${archivo}

                FOR    ${i}    IN RANGE    0    ${numero_paginas}
                    # Leer el contenido del PDF
                    ${informacion}    Leer PDF Plumber     ${archivo}    ${i}

                    # Identificador de bimestre
                    ${enumeracion_bimestre}    Get Regexp Matches    ${informacion}    ${REGEX_BIM}
                    ${bimestre}    Set Variable    ${enumeracion_bimestre}[0]

                    ${bimestre_lista}    Split String    string=${bimestre}    separator=X
                    ${bimestre_espacio}    Set Variable    ${bimestre_lista}[0]

                    ${bimestre_lista}     Split String    string=${bimestre_espacio}    separator=${SPACE}
                    ${bimestre}    Set Variable    ${bimestre_lista}[-2]

                    # Iterar sobre cada clave en la configuración de la ruta
                    FOR    ${key}    IN    @{ica.keys()}
                        ${es_regex}=    Evaluate    'ruta' in '''${key}'''
                        ${es_regex_2}=    Evaluate    'documento' in '''${key}'''
                        IF    not ${es_regex} and not ${es_regex_2}
                            ${matches}    Get Regexp Matches    ${informacion}     ${REGEX_EXP}
                            ${valor_final}   Set Variable    ${matches}[${ica}[${key}]]     
                            ${valor_final}    Replace String      ${valor_final}     ,    ${EMPTY}
                            ${valor_final_lista}    Split String    string=${valor_final}    separator=${SPACE}
                            ${valor_final}    Set Variable    ${valor_final_lista}[1]

                            # Revisar si el renglon ya fue registrado en la tabla
                            ${resultado_renglon}=    Query    SELECT COUNT(*) FROM consolidado_ica WHERE Renglon='${valor_final_lista}[0]' AND Usuario='${usuario}'

                            IF  ${resultado_renglon}[0][0] == 0
                                # Si no existe, insertar el renglon en la tabla
                                ${sql}    Catenate    
                                ...    INSERT INTO consolidado_ica (Renglon,`${bimestre}`,Usuario)
                                ...    VALUES ('${valor_final_lista}[0]','${valor_final}','${usuario}')
                                Execute Sql String   ${sql}
                            ELSE
                                # Si ya existe, actualizar el renglon en la tabla
                                ${sql}    Catenate    
                                ...    UPDATE consolidado_ica SET `${bimestre}`='${valor_final}' 
                                ...    WHERE Renglon='${valor_final_lista}[0]' AND Usuario='${usuario}'
                                Execute Sql String   ${sql}

                                # Hacer suma de los renglones
                                ${sql}    Catenate    
                                ...    UPDATE consolidado_ica SET Total = `1`+`2`+`3`+`4`+`5`+`6`
                                ...    WHERE Renglon='${valor_final_lista}[0]' AND Usuario='${usuario}'
                                Execute Sql String   ${sql}
                            END                
                        END
                    END
                END
            END
            #==================================================================================
            # Desconectar de la base de datos
            Disconnect From Database
            Log    Conexión cerrada exitosamente.    level=INFO
            ${completado}    Set Variable    ${True}
            ${error}    Set Variable     ${None} 
            BREAK
            #==================================================================================
        EXCEPT     AS    ${error}
            Disconnect From Database
            ${completado}=    Set Variable    ${False}
        END
    END
    RETURN   ${completado}




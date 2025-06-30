*** Settings ***
Library    RPA.FileSystem
Library    Collections
Library    String
Library    OperatingSystem
Resource    ${EXECDIR}/funciones/convertir_excel.robot
Resource    ${EXECDIR}/funciones/descargar_onedrive.robot
Resource    ${EXECDIR}/funciones/subir_insumo.robot

# *** Variables ***
# ${CONFIG}    ../config.yaml

# *** Tasks ***
# Clasificar En Formatos
#     [Documentation]    Clasifica formatos de la Dian
#     ${yaml_content}    Read File    ${config}
#     ${config}          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     Subir formatos   ${config}

*** Keywords ***
subir_archivos
    [Arguments]    &{parametros}
    ${reintentos}    Set Variable    2
    FOR    ${i}    IN RANGE    1    ${reintentos}
        TRY
            ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint

            #Conexion a sharepoint 
            ${token_refresco}    Get File    path=${CURDIR}/../token.txt    encoding=UTF-8

            ${archivos}=    RPA.FileSystem.List files in directory    ${CURDIR}/../${sharepoint['ruta_salidas_local']}

            FOR    ${archivo}    IN    @{archivos}
                ${archivo_path}=    Convert To String    ${archivo}
                Subida de insumo    refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}    secreto_cliente=${sharepoint['secreto_cliente']}    url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}    archivo_local=${archivo}    carpeta_onedrive=${sharepoint['ruta_salidas']}               
                OperatingSystem.Remove File    ${archivo_path}
            END
            ${completado}    Set Variable    ${True}
            ${error}    Set Variable     ${None} 
            BREAK
        EXCEPT     AS    ${error}
            ${completado}    Set Variable    ${False}
        END
    END
    RETURN    ${completado}     ${error}


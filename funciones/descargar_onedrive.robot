*** Settings ***
Library           OperatingSystem
Library           Collections
Library           RPA.MSGraph
Library           Dialogs


# *** Variables ***
# ${USUARIO}        Felipe.Castano@krypto.com.co
# ${CONTRASEÑA}     R3sp1r02026$
# ${ID_CLIENTE}     952ce091-2362-481e-aa37-61325d6f2e0f
# ${SECRETO_CLIENTE}  jjk8Q~9~wfmhW4b-N2FDX1dY7mT1_gvgH0Kivc7y
# ${URL_REDIRECCION}    https://login.microsoftonline.com/common/oauth2/nativeclient
# ${NOMBRE_DEL_SITIO}    kryptocolombia.sharepoint.com
# @{SCOPES}           Sites.ReadWrite.All    Files.ReadWrite.All    offline_access
# ${RUTA_ARCHIVO}       /Innovación y tecnología/IntegrIA/Proyectos Automatización/07 Medios Magnéticos/Terceros/ARK2 - Informe de Terceros.xlsx
# ${RUTA_DESCARGA}    ../insumos/     
# ${ARCHIVO_LOCAL}    ../insumos/ARK2 - Informe de Terceroscopy.xlsx
# ${CARPETA_ONEDRIVE}     /Innovación y tecnología/IntegrIA/Proyectos Automatización/07 Medios Magnéticos/Terceros/


# *** Tasks ***
# Probar descarga sharepoint
#     [Documentation]    Probar descarga de sharepoint
#     ${refresh_token}     Autorizar y Configurar Graph    ${id_cliente}        ${secreto_cliente}        ${url_redireccion}        ${scopes}
    #Listar archivos    ${id_cliente}        ${secreto_cliente}        ${url_redireccion}    ${nombre_del_sitio}     ${carpeta_onedrive}
    #Descargar Archivo de Sharepoint     ${id_cliente}        ${secreto_cliente}        ${url_redireccion}    ${nombre_del_sitio}     ${ruta_archivo}        ${ruta_descarga}
    #Subida de insumo    ${refresh_token}     ${id_cliente}    ${secreto_cliente}    ${url_redireccion}    ${nombre_del_sitio}     ${archivo_local}    ${carpeta_onedrive}    

*** Keywords ***
Autorizar y Configurar Graph 
    [Documentation]    Autorizar y obtener token
    [Arguments]        ${id_cliente}        ${secreto_cliente}        ${url_redireccion}       ${Scopes}     
    Set Environment Variable    PYTHONHTTPSVERIFY    0                       
    ${url_autorizacion}    Generate Oauth Authorization Url    client_id=${id_cliente}    client_secret=${secreto_cliente}    redirect_uri=${url_redireccion}    scopes=${scopes}
    Log    Abra la siguiente URL en su navegador e inicie sesión: ${url_autorizacion}    level=DEBUG    console=True
    ${url_oauth}=    Get Value From User   Ingrese la URL de redirección obtenida (debe incluir "code"):
    Log    url de autenticacion ${url_oauth}    level=DEBUG
    ${refresh_token}    Authorize And Get Token    authorization_url=${url_oauth}                
    Log      refresh token obtenido=${refresh_token}     level=DEBUG
    Create File    path=../logs/token.txt    content=${refresh_token}     encoding=UTF-8
    RETURN     ${refresh_token}   


Descargar Archivo de Sharepoint
    [Documentation]    Descargar archivo de sharepoint
    [Arguments]       ${refresh_token}    ${id_cliente}        ${secreto_cliente}        ${url_redireccion}    ${nombre_del_sitio}     ${ruta_archivo}        ${ruta_descarga}           
    TRY
        ${token}    Configure Msgraph Client    client_id=${id_cliente}     client_secret=${secreto_cliente}     redirect_uri=${url_redireccion}    refresh_token=${refresh_token}
        Log    Refresh token: ${token}    level=DEBUG
        ${sitio}    Get Sharepoint Site    ${nombre_del_sitio}    
        Log    Sitio ${sitio}    level=DEBUG
        ${drives}    List SharePoint Site Drives    ${sitio}
        Log    Available Drives ${drives}    level=DEBUG
        Download File From Sharepoint        target_file=${ruta_archivo}    site=${sitio}    to_path=${ruta_descarga}    drive=${drives}[3]
        ${estado}    Set Variable    Exitoso
    EXCEPT    AS    ${error}
        IF    'Not Found' in $error
            ${estado}    Set Variable    No encontrado
        ELSE
            ${estado}    Set Variable    Fallido
        END
    END
    RETURN     ${estado} 


Listar archivos
    [Documentation]    Descargar archivo de sharepoint
    [Arguments]       ${refresh_token}    ${id_cliente}        ${secreto_cliente}        ${url_redireccion}    ${nombre_del_sitio}     ${ruta_carpeta}
    TRY          
        ${token}    Configure Msgraph Client    client_id=${id_cliente}     client_secret=${secreto_cliente}     redirect_uri=${url_redireccion}    refresh_token=${refresh_token}
        Log    Refresh token: ${token}    level=DEBUG
        ${sitio}    Get Sharepoint Site    ${nombre_del_sitio}    
        Log    Sitio ${sitio}    level=DEBUG
        ${drives}    List SharePoint Site Drives    ${sitio}
        Log    Available Drives ${drives}    level=DEBUG
        ${files}    List Files In Sharepoint Site Drive    site=${sitio}    drive=${drives}[3]    target_folder=${ruta_carpeta}
        Log     ${files}    level=DEBUG
        ${estado}    Set Variable    Exitoso
    EXCEPT    AS    ${error}
        IF    'Not Found' in $error
            ${estado}=    Set Variable    No encontrado
            ${files}=     Create List
        ELSE
            ${estado}=    Set Variable    Fallido
            ${files}=     Create List
        END
    END
    RETURN     ${estado}    ${files}

Subida de insumo
    [Documentation]    Subida de insumo
    [Arguments]        ${refresh_token}    ${id_cliente}    ${secreto_cliente}    ${url_redireccion}    ${nombre_del_sitio}     ${archivo_local}    ${carpeta_onedrive}                
    ${token}    Configure Msgraph Client    client_id=${id_cliente}     client_secret=${secreto_cliente}     redirect_uri=${url_redireccion}    refresh_token=${refresh_token}
    ${sitio}    Get Sharepoint Site    ${nombre_del_sitio}    
    Log    Sitio ${sitio}    level=DEBUG
    ${drives}    List SharePoint Site Drives    ${sitio}
    Log    Available Drives ${drives}    level=DEBUG
    Upload File To Onedrive    file_path=${archivo_local}   target_folder=${carpeta_onedrive}   drive=${drives}[3]
    RETURN     'Exitoso'








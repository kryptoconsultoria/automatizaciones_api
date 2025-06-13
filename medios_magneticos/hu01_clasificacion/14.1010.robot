*** Settings ***
Library           DatabaseLibrary
Library           Collections
Library           OperatingSystem
Library           RPA.FileSystem
Library           String
Resource          ../funciones/leer_pdf.robot
Resource          ../funciones/completar_informacion_dian.robot
Resource          ../funciones/descargar_onedrive.robot


*** Variables ***
#${CONFIG_FILE}    ../config.yaml
#${CONFIG_FILE_PDF}    ../config_pdf.yaml
${REGEX_NUMERO}       (?:\\d{1,3}(?:[,.]\\d{3}){2,}|\\d{6,}|\\d{3}[,.]\\d{3})
${REGEX_PORCENTAJE}      (?:(?:[0-9]{1,2}(?:[.,]\\d+)?|100(?:[.,]0+)?))%

# *** Tasks ***
# LLenar PDF 2276
#     [Documentation]    Clasifica formatos de la Dian
#     Leer y cargar la configuración desde el archivo YAML
#     ${yaml_content}=    Read File    ${config_file}
#     ${yaml_content_pdf}=    Read File    ${config_file_pdf}
   
#     ${config_file}=          Evaluate    yaml.safe_load('''${yaml_content}''')    modules=yaml
#     ${config_file_pdf}=      Evaluate    yaml.safe_load('''${yaml_content_pdf}''')    modules=yaml

#     Formato 1010    ${config_file}     ${config_file_pdf}

*** Keywords ***
1010    
   [Documentation]    Lee archivos PDF, extrae información utilizando expresiones regulares y clasifica los datos en la base de datos correspondiente
   [Arguments]    &{parametros}
   ${reintentos}    Set Variable    2
   FOR    ${i}    IN RANGE    1    ${reintentos}
      TRY
         # Obtener las rutas locales y la configuración de la base de datos
         ${pdf_1010}=    Get From Dictionary    ${parametros['config_pdf']['rutas_pdf']}   pdf_1010
         ${bd_config}=       Get From Dictionary    ${parametros['config_file']['credenciales']}    base_datos
         ${sharepoint}   Get From Dictionary   ${parametros['config_file']['credenciales']}   sharepoint
         ${usuario}   Get From Dictionary   ${parametros['config_file']['credenciales']}   usuario


         # Obtener cliente a procesar
         ${cliente}=   Get From Dictionary   ${parametros['config_file']['credenciales']}   cliente

         #Conexion a sharepoint
         ${token_refresco}    Get File    path=${CURDIR}/../logs/token.txt    encoding=UTF-8

         # Conectar a la base de datos
         Connect To Database    pymysql    ${bd_config["nombre_bd"]}    ${bd_config["usuario"]}    ${bd_config["contrasena"]}    ${bd_config["servidor"]}    ${bd_config["puerto"]}


         ${sql}     Catenate  
         ...    TRUNCATE TABLE formato_1010
         Execute Sql String   ${sql}

         ${sql}=     Execute SQL Script    ${CURDIR}/../sql/tablas_temporales.sql
         ${sql}=     Execute SQL Script    ${CURDIR}/../sql/rues.sql

         #==================================================================================
         # validar si la ruta contiene la palabra insumos si la contiene solo sube el excel asociado con el cliente
         ${carpeta_1010}    Replace String    ${pdf_1010["ruta_carpeta"]}    search_for=CLIENTE    replace_with=${cliente}
         ${ruta_nube}    Replace String    ${pdf_1010["ruta_nube"]}    CLIENTE   ${cliente}

         #Borrar archivos de cada carpeta
         OperatingSystem.Remove Files    ${carpeta_1010}/*

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
               ${estado_descarga}      Descargar Archivo de Sharepoint   refresh_token=${token_refresco}    id_cliente=${sharepoint['id_cliente']}     secreto_cliente=${sharepoint['secreto_cliente']}     url_redireccion=${sharepoint['uri_redireccion']}     nombre_del_sitio=${sharepoint['nombre_sitio']}     ruta_archivo=${ruta_nube}${archivo}     ruta_descarga=${carpeta_1010}
               IF  '${estado_descarga}' == 'Fallido'
                  ${completado}=    Set Variable    ${False}
                  RETURN    ${completado}
               ELSE IF    '${estado_descarga}' == 'No encontrado'
                  CONTINUE
               END
         END
         #==================================================================================

         # Iterar sobre cada ruta en rutas_locales
         ${resultados}=    Query    SELECT IdCliente,Nombre,DV,Direccion,IdPais,IdDepartamento,IdMunicipio FROM cliente WHERE Nombre='${cliente}'

         FOR    ${fila}    IN    @{resultados}

            ${nit}=           Set Variable    ${fila}[0]
            ${nombre}=           Set Variable    ${fila}[1]
            ${dv}=           Set Variable    ${fila}[2]
            ${direccion}=          Set Variable    ${fila}[3]
            ${pais}=    Set Variable    ${fila}[4]
            ${ciudad}=           Set Variable    ${fila}[5]
            ${municipio}=         Set Variable    ${fila}[6]


            ${archivos}=    OperatingSystem.List Files In Directory     ${carpeta_1010}

            FOR    ${file}    IN    @{archivos}
                  ${archivo}=    Set Variable   ${carpeta_1010}${file}     

                  # Leer el contenido del PDF utilizando PDF Plumber
                  ${page_number}=    Set Variable    0
                  ${informacion}=    Leer PDF Plumber     ${archivo}    pagina=${page_number}

                  # Extraer tabla
                  ${informacion}=    Convert To Lower Case    ${informacion}

                  # Extraer texto después de la primera aparición de "accionista"

                  ${partes}    Split String    ${informacion}    accionista    1
                  ${parte_derecha}    Get From List    ${partes}    1

                  # Dividir usando "total" para encontrar todas sus apariciones
                  ${totales}=    Split String    ${parte_derecha}    total

                  # Determinar cuántas apariciones de "total" existen
                  ${longitud}=    Get Length    ${totales}

                  # Si hay más de una aparición de "total", tomar hasta la segunda
                  IF    ${longitud} > 2    
                     ${informacion}=    Catenate    SEPARATOR=total    ${totales}[0]    ${totales}[1]
                  ELSE    
                     ${informacion}=    Catenate    SEPARATOR=total    ${totales}[0]
                  END

                  # Iterar sobre cada clave en la configuración de la ruta
                  ${matches_numeros}=    Get Regexp Matches    ${informacion}     ${REGEX_NUMERO}
                  ${matches_porcentajes}=    Get Regexp Matches    ${informacion}     ${REGEX_PORCENTAJE}

                  ${contador}=        Set Variable     1

                  FOR    ${match}    IN    @{matches_porcentajes}
                     ${item_par}=    Evaluate    (${contador}-1)*2
                     ${item_siguiente}=    Evaluate    ${item_par}+1
                     ${item_impar}=    Evaluate    ((${contador}-1)*2)-1

                     ${NumIdSocio}               Set Variable    ${matches_numeros}[${item_par}]
                     ${NumIdSocio}=    Replace String      ${NumIdSocio}     .    ${EMPTY}   
                     ${datos}    ${completado}=     Consulta DIAN     ${NumIdSocio}
                     
                     IF    $datos is not None    
                        ${DV}                       Set Variable    ${datos[0]}
                        ${PrimerApellido}           Set Variable    ${datos[2]}
                        ${SegundoApellido}          Set Variable    ${datos[3]}
                        ${PrimerNombreSocio}        Set Variable    ${datos[4]}
                        ${OtrosNombresSocio}        Set Variable    ${datos[5]}

                     ELSE
                        ${DV}                       Set Variable    ${EMPTY}
                        ${PrimerApellido}           Set Variable    ${EMPTY}
                        ${SegundoApellido}          Set Variable    ${EMPTY}
                        ${PrimerNombreSocio}        Set Variable    ${EMPTY}
                        ${OtrosNombresSocio}        Set Variable    ${EMPTY}
                        ${RazonSocial}              Set Variable    ${EMPTY}
                     END

                     ${RazonSocial}              Set Variable    ${cliente}
                     ${PorcentajeParticipacion}  Set Variable    ${match}

                     ${contiene_coma}=    Evaluate    "',' in '''${PorcentajeParticipacion}'''"
                     ${contiene_punto}=    Evaluate    "'.' in '''${PorcentajeParticipacion}'''"

                     IF    ${contiene_coma}
                        ${decimales}  Split String    ${PorcentajeParticipacion}    ,
                        ${PorcentajeParticipacion}=    Replace String      ${PorcentajeParticipacion}     ,    ${EMPTY}
                        ${cant_decimales}    Get Length     ${decimales}[1]
                     ELSE IF    ${contiene_punto}
                        ${decimales}  Split String    ${PorcentajeParticipacion}    .
                        ${PorcentajeParticipacion}=    Replace String      ${PorcentajeParticipacion}     .    ${EMPTY}
                        ${cant_decimales}    Get Length     ${decimales}[1]
                     ELSE
                        ${cant_decimales}    Set Variable      0
                     END

                     ${PorcentajeParticipacion}=    Replace String      ${PorcentajeParticipacion}     %    ${EMPTY} 

                     ${ValorPatAcciones}         Set Variable    ${matches_numeros}[${item_siguiente}] 

                     ${sql}     Catenate  
                     ...    INSERT INTO formato_1010 (NumIdSocio,DV,PrimerApellidoSocio,SegundoApellidoSocio,
                     ...    PrimerNombreSocio,OtrosNombresSocio,RazonSocial,Direccion,CodDpto,CodMcp,PaisResidencia,
                     ...    PorcentajeParticipacion,ValorPatAcciones,PorcentajeParticipacionDecimal,Usuario) 
                     ...    VALUES ('${NumIdSocio}','${DV}','${PrimerApellido}','${SegundoApellido}','${PrimerNombreSocio}',
                     ...    '${OtrosNombresSocio}','${RazonSocial}','${direccion}','${pais}','${ciudad}','${municipio}',
                     ...    '${PorcentajeParticipacion}','${ValorPatAcciones}','${cant_decimales}','${usuario}')
                     Execute Sql String   ${sql}         

                     ${contador}=    Evaluate    ${contador}+1
                  END

                  # RUES
                  ${sql}     Catenate  
                  ...    UPDATE formato_1010 a
                  ...    INNER JOIN cross_rues b ON a.NumIdSocio COLLATE utf8mb4_unicode_ci  = b.NumId COLLATE utf8mb4_unicode_ci 
                  ...    SET
                  ...    a.TipoDoc = b.TipoDoc,
                  ...    a.DV=IF(TRIM(b.TipoDoc) IN ('11','12','13','21','22','41'),'',a.DV);

                  #Balances
                  ${sql}     Catenate  
                  ...    UPDATE formato_1010 a
                  ...    INNER JOIN balances b ON a.NumIdSocio COLLATE utf8mb4_unicode_ci  = b.NumId COLLATE utf8mb4_unicode_ci 
                  ...    SET
                  ...    a.TipoDoc = b.TipoDoc,
                  ...    a.DV=IF(TRIM(b.TipoDoc) IN ('11','12','13','21','22','41'),'',a.DV);
                  Execute Sql String   ${sql}
            END
         END
         # Desconectar de la base de datos
         Disconnect From Database
         ${completado}=    Set Variable    ${True}
         BREAK
      EXCEPT      AS    ${error}
         Disconnect From Database
         ${completado}=    Set Variable    ${False}
      END
   END
   RETURN    ${completado}
        

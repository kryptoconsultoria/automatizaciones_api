import openai
from robot.api.deco import library, keyword
from pydantic import BaseModel
from pathlib import Path


class ExtraccionRetefuente(BaseModel):
    RetencionesVentas: str
    RetencionesHonorarios: str
    RetencionesServicios: str
    RetencionesComisiones: str
    RetencionesInteresesRendimientos: str
    RetencionesArrendamientos: str
    RetencionesOtrosConceptos: str
    RetencionIVA: str
    RetencionDividendosParticipaciones: str
    RetencionEnajenacionActivosFijos: str
    RetencionIngresosTarjetas: str
    RetencionLoteriasApuestas: str
    NIT: str
    RetencionSalarios: str
    RetencionImpuestoTimbre: str
    RetencionDividendosSociales: str


@library
class LibreriaGPT:
    def __init__(self):
        self.api_key = None
    
    @keyword("Autenticar ChatGPT") 
    def autenticar(self, api_key):
        """Autentica con OpenAI utilizando la API Key proporcionada."""
        self.api_key = api_key
        openai.api_key = self.api_key
        
    @keyword("Subir Archivos") 
    def subir_archivos(self,ruta_pdf):
        
        if not self.api_key:
            raise Exception("No se ha autenticado. Usa el keyword 'Autenticar ChatGPT' primero.")
        
        pathlist= Path(ruta_pdf).glob('**/*.pdf')
        
        list_files=[str(path) for path in pathlist] 

        vector_store = openai.beta.vector_stores.create(name="Facturas Retefuente",expires_after={"anchor": "last_active_at","days": 1})

        file_streams = [open(path, "rb") for path in list_files]

        openai.beta.vector_stores.file_batches.upload_and_poll(
        vector_store_id=vector_store.id, files=file_streams
        )

        return vector_store.id
        
    @keyword("Crear Asistente") 
    def crear_asistente(self,assist_instructions,assist_model,id_vector_store=''):
        assistant = openai.beta.assistants.create(
            name="Asistente retefuente",
            instructions=assist_instructions,
            model=assist_model,
            tools=[{"type": "file_search"}],
            response_format={ "type": "json_object" }
            #tool_resources={"file_search": {"vector_store_ids": [id_vector_store]}},
        )
        return assistant.id
    
    @keyword("Crear Hilo")
    def crear_hilo(self,prompt):     
        if not self.api_key:
            raise Exception("No se ha autenticado. Usa el keyword 'Autenticar ChatGPT' primero.")
            
        thread = openai.beta.threads.create(
        messages=[
            {
            "role": "user",
            "content": prompt
            # "attachments": [
            #     { "file_id": message_file.id, "tools": [{"type": "file_search"}]}
            # ],
            }
        ]
        )
        return thread.id
    

    @keyword("Actualizar Hilo")
    def actualizar_hilo(self,id_hilo,archivo_pdf):     
        if not self.api_key:
            raise Exception("No se ha autenticado. Usa el keyword 'Autenticar ChatGPT' primero.")
        
        if archivo_pdf is not None:
            message_file = openai.files.create(                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
                file=open(archivo_pdf, "rb"), purpose="assistants"
            )

        thread = openai.beta.threads.update(
            id_hilo,
            metadata={
                "modified": "true",
                "attachments": [
                { "file_id": message_file.id, "tools": [{"type": "file_search"}]}
                ],
            }
        )
        return thread.id
    

    @keyword('Correr hilo')
    def correr_hilo(self,id_thread,assistant_id):
        run = openai.beta.threads.runs.create_and_poll(
            thread_id=id_thread, assistant_id=assistant_id
        )
        

        messages = list(openai.beta.threads.messages.list(thread_id=id_thread, run_id=run.id))
        message_content = messages[0].content[0].text
        return message_content.value
            
    
if __name__=="__main__":
    libreria = LibreriaGPT()

    api_key= "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"

    instructions="""
        You are an excellent colombian accountant with high capabilities of system programming responsible for preparing the magnetic media to present information to the DIAN. 
        You need to review PDF files containing third-party information related to withholding tax, which must be reported in the DIAN's required format 1003 for the presentation of magnetic media. In this format, 
        one of the items to be reported is the withheld amount. To extract this information from the PDF database, you should consider the following.
        Extract only the required data.         
        Respond only with the required output data, avoiding any additional text.        
        Only provide the data that appears in the PDF. 
        If no data is available, assign the value 0.

    """
    outputs="""
        "RetencionesVentas": "0",
        "RetencionesHonorarios": "in this field, extract the withholding value associated with 'Honorarios', 'Retención en la fuente', 'Retefuente', or any related terms",
        "RetencionesServicios": "in this field, extract the withholding value for services, if it appears",
        "RetencionesComisiones": "if there is a second occurrence of withholding for 'Honorarios' or related terms, place it here",
        "RetencionesInteresesRendimientos": "In this field, extract the withholding value if 'rendimientos financieros' or related terms are mentioned",
        "RetencionesArrendamientos": "0",
        "RetencionesOtrosConceptos": "in this field, extract the withholding value for 'Otros Ingresos Tributarios' or if the term 'software' appears",
        "RetencionIVA": "0",
        "RetencionDividendosParticipaciones": "0",
        "RetencionEnajenacionActivosFijos": "0",
        "RetencionIngresosTarjetas": "0",
        "RetencionLoteriasApuestas": "0",
        "NIT": "if you can see the nit extract the nit in this field",
        "RetencionSalarios": "0",
        "RetencionImpuestoTimbre": "0",
        "RetencionDividendosSociales": "0"
        """
    
    libreria.autenticar(api_key)

    print('===================Crear asistente========================')
    #id_vector=libreria.subir_archivos('./insumos/pdf_1003')
    # id_asistente=libreria.crear_asistente(assist_instructions=instructions,assist_model='gpt-4o')
    # print(id_asistente)
    # print('===================Crear hilo========================')
    id_hilo=libreria.crear_hilo(prompt=outputs,archivo_pdf='C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/pdf_1003/1. ARK2.pdf')
    # print(id_hilo)
    # print('===================Crear hilo========================')
    id_asistente='asst_vnavg8ET429ijoXVRva8gWYz'
    #id_hilo='thread_X2xswrZISzSQpmqCRwbaQKTY'
    
    contenido=libreria.correr_hilo(id_hilo,id_asistente)
    print(contenido)

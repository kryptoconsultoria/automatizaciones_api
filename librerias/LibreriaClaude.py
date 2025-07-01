from pydantic import BaseModel, Field
import anthropic
import instructor
from robot.api.deco import library, keyword
import base64
import json
from PyPDF2 import PdfReader, PdfWriter
from io import BytesIO

class RespuestaClaude(BaseModel):
    value_1302: dict = Field(default_factory=dict, alias="1302")
    value_1304: dict = Field(default_factory=dict, alias="1304")
    value_1303: dict = Field(default_factory=dict, alias="1303")
    value_1305: dict = Field(default_factory=dict, alias="1305")
    value_1306: dict = Field(default_factory=dict, alias="1306")
    value_1308: dict = Field(default_factory=dict, alias="1308")
    NumId: str = Field(default="0", alias="NumId")
    DV: str = Field(default="0", alias="DV")
    RazonSocial: str = Field(default="0", alias="RazonSocial")
    PrimerApellido: str = Field(default="0", alias="PrimerApellido")
    SegundoApellido: str = Field(default="0", alias="SegundoApellido")
    PrimerNombre: str = Field(default="0", alias="PrimerNombre")
    OtrosNombres: str = Field(default="0", alias="OtrosNombres")

class Config:
    populate_by_name = True

@library
class LibreriaClaude:
    
    def __init__(self):
        self.api_key = None
        self.client = None

    @keyword('Autenticar')
    def autenticar(self, api_key: str) -> None:
        """
        Autentica utilizando la API key y crea la instancia del cliente Anthropic.
        """
        self.api_key = api_key
        self.client = anthropic.Client(api_key=self.api_key)
        self.client = instructor.from_anthropic(self.client)

    @keyword("Pasar a base 64")
    def base_64(self, ruta_pdf: str, pass_pdf: str = None) -> str:
        """
        Abre el PDF, maneja protección con contraseña si es necesario,
        y lo codifica en base64.

        Args:
            ruta_pdf (str): Ruta del archivo PDF.
            pass_pdf (str, optional): Contraseña del PDF. Defaults to None.

        Returns:
            str: Contenido del PDF codificado en base64.
        """
        with open(ruta_pdf, "rb") as pdf_file:
            reader = PdfReader(pdf_file)
            
            if reader.is_encrypted:
                try:
                    # Intentar acceder a la primera página sin decrypt
                    _ = reader.pages[0]
                except Exception:
                    # Si falla, intentar desencriptar con contraseña
                    if pass_pdf is None:
                        raise Exception("El PDF está protegido y no se proporcionó una contraseña.")
                    if reader.decrypt(pass_pdf) == 0:
                        raise Exception("Contraseña incorrecta o no se pudo desencriptar el PDF.")

            # Guardar el PDF (desprotegido si aplicaba) en memoria
            output = BytesIO()
            writer = PdfWriter()

            for page in reader.pages:
                writer.add_page(page)

            writer.write(output)
            output.seek(0)

            # Codificar en base64
            encoded_bytes = base64.b64encode(output.read())

        encoded_string = encoded_bytes.decode('utf-8')
        return encoded_string

    @keyword('Consulta Claude')
    def solicitud(self, modelo: str, pdf_base_64: str, prompt: str):
        """
        Envía una solicitud a Claude utilizando el modelo indicado, el PDF codificado y un prompt.

        Args:
            modelo (str): Nombre del modelo a utilizar.
            pdf_base_64 (str): Cadena en base64 del PDF.
            prompt (str): Instrucciones para extraer la información requerida.

        Returns:
            dict: Respuesta recibida de Claude.
        """
        message_batch = self.client.messages.create(
            model=modelo,
            max_tokens=1024,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "document",
                            "source": {
                                "type": "base64",
                                "media_type": "application/pdf",
                                "data": pdf_base_64
                            }
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ]
                }
            ],
            response_model=RespuestaClaude
        ) 
        respuesta=message_batch.model_dump_json(by_alias=True) 
        return respuesta
    
    @keyword('Obtener valor de campo')
    def obtener_valor(self, json_str: str, campo: str):
        """
        Extrae el valor de un campo específico del JSON.

        Args:
            json_str (str): String JSON.
            campo (str): Nombre del campo a extraer.

        Returns:
            str: Valor del campo o cadena vacía si no existe.
        """
        try:
            data = json.loads(json_str)
            return str(data.get(campo, ""))
        except json.JSONDecodeError:
            return ""
    
if __name__ == "__main__":
    print('testeo')
    model = "claude-3-5-sonnet-20241022"
    ruta_pdf = "C:/Users/Krypto/PycharmProjects/medios_magneticos/insumos/pdf_1003/EASY TECH/BOLIVAR -4516  EASY TECH GLOBAL COLOMBIA SAS - RETEFUENTE  2024.pdf"
    token = "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"
    prompt = """You are an excellent colombian accountant with high capabilities of system programming responsible for preparing the magnetic media to present information to the DIAN. 
    You need to review PDF files containing third-party information related to withholding tax, which must be reported in the DIAN's required format 1003 for the presentation of magnetic media. In this format, 
    one of the items to be reported is the withheld amount. To extract this information from the PDF database, you should consider the following.
    Extract only the required data.         
    Respond only with the required output data, avoiding any additional text.        
    Only provide the data that appears in the PDF. 
    If no data is available, assign the value 0.
    
    "1302": "0",
    "1304": "in this field, extract the withholding value associated with 'Honorarios', 'Retención en la fuente', 'Retefuente', or any related terms",
    "1303": "in this field, extract the withholding value for services, if it appears",
    "1305": "if there is a second occurrence of withholding for 'Honorarios' or related terms, place it here",
    "1306": "In this field, extract the withholding value if 'rendimientos financieros' or related terms are mentioned",
    "1307": "0",
    "1308": "in this field, extract the withholding value for 'Otros Ingresos Tributarios' or if the term 'software' appears",
    "1309": "0",
    "1310": "0",
    "1311": "0",
    "1312": "0",
    "1313": "0",
    "NIT": "if you can see the nit extract the nit in this field",
    "1301": "0",
    "1314": "0",
    "1320": "0"
    """
    libreria = LibreriaClaude()
    libreria.autenticar(token)
    base64_str = libreria.base_64(ruta_pdf,'901236432')
    resultado = libreria.solicitud(model, base64_str, prompt)
    print(resultado)
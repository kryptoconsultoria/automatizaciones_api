import openai
from robot.api.deco import library, keyword
from pathlib import Path
from pydantic import BaseModel

class AnswerFormat(BaseModel):
    HeadquarterAddress: str
    HeadquarterCountry:  str
    HeadquarterCity: str
    ColombiaAddress: str
    ColombiaCity: str
    HeadquarterIdNumber:str


@library
class LibreriaPerplexity:
    def __init__(self):
        self.api_key = None
    
    @keyword("Autenticar Perplexity") 
    def autenticar(self, api_key):
        """Autentica con OpenAI utilizando la API Key proporcionada."""
        self.api_key = api_key
        self.base_url = "https://api.perplexity.ai"
        openai.api_key = self.api_key
        openai.base_url= self.base_url
        
    @keyword("Consultar PerPlexity") 
    def consultar_perplexity(self, model, prompt, instructions):
        response_stream = openai.chat.completions.create(
            model=model,
            messages=[
                {
                    "role": "system",
                    "content": prompt
                },
                {
                    "role": "user",
                    "content": instructions
                },
            ],
            response_format={"type": "json_schema", "json_schema": {"schema": AnswerFormat.model_json_schema()}}
        )
        generated_text = response_stream.choices[0].message.content

        return generated_text

    
if __name__=="__main__":
    libreria = LibreriaPerplexity()

    api_key= "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"

    prompt='You are an advanced search engine designed to retrieve detailed business information.'

    instructions="""
        with the  provided name of a business BUSINESS_NAME and optionally the city of its headquarters CITY_HEADQUARTERS, search for and retrieve the full name and the headquarter address, including the city and country. 
        If applicable, also retrieve the address and city of any subsidiary or branch of the company located in Colombia.
        
        # Steps
        
        1. Identify the full name and headquarter address of the business.
        2. Determine the country and city of the headquarter address.
        3. If applicable, locate the address and city of a Colombian branch or subsidiary.
        
        # Output Items
        Please output only a JSON object containing the following fields:
        
        "Headquarter_Address": "Address of the business headquarter, only get the address",
        "Headquarter_Country": "Country of the business headquarter, only get the Country",
        "Headquarter_City": "City of the business headquarter, only get the City",
        "Colombia_Address": "Address of the business branch or subsidiary in Colombia, only get the address",
        "Colombia_City": "City of the business branch or subsidiary in Colombia, only get the City"
        
        
        # Notes
        
        - Ensure accuracy in the name and address details.
        - If there is no branch or subsidiary in Colombia, leave the respective fields empty.
        - When city information for the headquarter is provided in the prompt, cross-verify with the search results.
    """
    libreria.autenticar(api_key)

    print('===================Crear asistente========================')
    #id_vector=libreria.subir_archivos('./insumos/pdf_1003')
    # id_asistente=libreria.crear_asistente(assist_instructions=instructions,assist_model='gpt-4o')
    # print(id_asistente)
    # print('===================Crear hilo========================')
    instructions=instructions.replace('BUSINESS_NAME','CORPRENAL SA')
    instructions=instructions.replace('CITY_HEADQUARTERS','GUAYAQUIL')
    print(libreria.consultar_perplexity(model='sonar-pro',prompt=prompt,instructions=instructions))
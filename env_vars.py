from dotenv import load_dotenv
load_dotenv()
import os

#==========================================================\
# Variables de entorno medios magneticos
#==========================================================
CHAT_GPT_TOKEN = os.environ.get("CHAT_GPT_TOKEN")
CLAUDE_TOKEN = os.environ.get("CLAUDE_TOKEN")
CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS = os.environ.get("CLIENT_ID_OFFICE_MEDIOS_MAGNETICOS")
CONTRASENA_BD_MEDIOS_MAGNETICOS = os.environ.get("CONTRASENA_BD_MEDIOS_MAGNETICOS")
PERPLEXITY_TOKEN = os.environ.get("PERPLEXITY_TOKEN")
SECRET_ID_MEDIOS_MAGNETICOS = os.environ.get("SECRET_ID_MEDIOS_MAGNETICOS")

#==========================================================\
# Variables de entorno medios distritales
#==========================================================
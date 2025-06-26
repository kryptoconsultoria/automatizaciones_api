from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import subprocess
import os
import sys
import logging
import ast,json


app = FastAPI()

class RunMedios(BaseModel):
    cliente: str
    usuario: str

@app.post("/medios_magneticos")
async def medios_magneticos(req: RunMedios):
    #sys.stdout = open(os.devnull, 'w')
    #sys.stderr = open(os.devnull, 'w')
    #logging.disable(logging.CRITICAL)

    date_str = datetime.now().strftime("%Y-%m-%d_%H_%M_%S")
    output_dir = f"medios_magneticos/logs/{date_str}/"
    os.makedirs(output_dir, exist_ok=True)

    # rutas resultado salida json 
    salida_json = os.path.join("medios_magneticos", f"salida.json")

    # Comando para ejecutar el robot
    command = [
        "robot",
        "--outputdir", output_dir,
        "--output", "output.xml",
        "--log", "log.html",
        "--report", "report.html",
        "--variable", f"CLIENTE:{req.cliente}",
        "--variable", f"USUARIO:{req.usuario}",
        "--console", "none",
        "medios_magneticos/main.robot"
    ]

    # Ejecutar de forma no bloqueante
    subprocess.run(command)

    if os.path.exists(salida_json):
        with open(salida_json, "r", encoding="utf-8") as f:
            datos = json.load(f)
        return {
            "Tarea": datos['tarea'],
            "HistoriaUsuario": datos['hu'],
            "Estado": datos['estado'],
            "ErrorDetalle": datos['error_detalle']
        }
    else:
        return {
            "Tarea": '',
            "HistoriaUsuario": '',
            "Estado": 'Error',
            "ErrorDetalle": 'No se generó archivo JSON'
        }

# @app.post("/medios_distritales")
# async def medios_distritales(req: RunMedios):
#     pass

from fastapi import FastAPI
from pydantic import BaseModel
from datetime import datetime
import subprocess
import os

app = FastAPI(
    title="Automatizaciones API",
    description="API para ejecutar robots en robot Framework.",
    version="1.0.0"
)

class RunMediosMagneticos(BaseModel):
    cliente: str
    usuario: str

@app.post("/medios_magneticos")
async def medios_magneticos(req: RunMediosMagneticos):
    """
    Ejecuta de manera asincrónica el flujo de medios magneticos y retorna el resultado.

    - **cliente**: Nombre del cliente.
    - **usuario**: Nombre del usuario.
    """
    date_str = datetime.now().strftime("%Y-%m-%d_%H_%M_%S")
    output_dir = f"medios_magneticos/logs/{date_str}/"

    # Crear el directorio de salida si no existe
    os.makedirs(output_dir, exist_ok=True)

    # Ejecutar el archivo .robot pasando las variables desde la solicitud
    result = subprocess.run([
        "robot",
        "--outputdir", output_dir,
        "--output", "output.xml",
        "--log", "log.html",
        "--report", "report.html",
        "--variable", f"CLIENTE:{req.cliente}",
        "--variable", f"USUARIO:{req.usuario}",
        "medios_magneticos/main.robot"
    ], capture_output=True, text=True)

    return {
        "stdout": result.stdout,
        "stderr": result.stderr,
        "returncode": result.returncode
    }

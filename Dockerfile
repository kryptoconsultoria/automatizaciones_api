# Etapa 1: Build con tests RPA
FROM python:3.12-slim AS build

WORKDIR /app

# Copia de dependencias y preparación del entorno
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Instalación de RobotFramework y RPA Framework
RUN pip install robotframework rpaframework>=29.0.0

# Ejecución de tests RPA durante el build
RUN robot --outputdir robot-results tests/

# Etapa 2: Imagen de producción ligera
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copia únicamente el código de la app
COPY --from=build /app/app/ app/
COPY requirements.txt .

# Instalación de dependencias necesarias (sin herramientas de test)
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 82
ENV PORT=82

# Comando final para arrancar FastAPI
CMD ["uvicorn", "app.main:app", "--host", "host.docker.internal", "--port", "82"]

# 1. Etapa de build: instalar dependencias y ejecutar tests
FROM python:3.12-slim AS build

WORKDIR /app

# Copia dependencias y optimiza cache de Docker
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copia el código y los tests RPA
COPY app/ app/
COPY tests/ tests/

# Ejecuta tests RobotFramework
RUN pip install robotframework
RUN robot --outputdir robot-results tests/

# 2. Etapa de producción: imagen limpia solo con runtime
FROM python:3.12-slim AS runtime

WORKDIR /app

# Copia solo lo esencial
COPY --from=build /app/app/ app/
COPY --from=build /app/requirements.txt .

# Instala solo dependencias necesarias (sin robot ni herramientas de build)
RUN pip install --no-cache-dir -r requirements.txt

ENV PORT=8000
EXPOSE 8000

# Comando final para ejecutar tu app
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
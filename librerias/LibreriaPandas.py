import pandas as pd
import numpy as np
from robot.api.deco import library, keyword
from charset_normalizer import from_path


@library
class LibreriaPandas:

    def __init__(self):
        self.excel = None

    @keyword("Detectar codificacion")
    def detectar_codificacion(self, archivo_csv):
        """Detecta la codificación de un archivo CSV."""
        result = from_path(archivo_csv).best()
        return result.encoding

    @keyword("Abrir Excel")
    def abrir_excel(self, file_path):
        """
        Abre un archivo Excel y lo almacena en la instancia.

        Args:
            file_path: Ruta del archivo Excel.

        Returns:
            Mensaje confirmando la apertura del archivo Excel.
        """
        self.excel = pd.ExcelFile(file_path)
        return f"Archivo Excel abierto: {file_path}"

    @keyword("Cerrar Excel")
    def cerrar_excel(self):
        """
        Cierra el archivo Excel previamente abierto.

        Returns:
            Mensaje confirmando el cierre del archivo Excel.
        """
        if self.excel:
            self.excel.close()
            self.excel = None
            return "Archivo Excel cerrado correctamente."
        else:
            return "No hay ningún archivo Excel abierto para cerrar."

    @keyword("Completar Datos")
    def leer_y_completar_datos(self, sheet_name, output_path, indices):
        """
        Lee una hoja del archivo Excel previamente abierto, completa los valores nulos en columnas específicas
        utilizando forward fill, y guarda el resultado en un archivo CSV.
        
        Primero, para las filas que ya están diligenciadas (es decir, que tienen al menos un dato en las columnas seleccionadas),
        se completan las celdas faltantes con la cadena "NA". Luego, para las filas que no tienen datos (todas las celdas NaN en esas columnas),
        se aplica forward fill para completar la información.
        
        Args:
            sheet_name: Nombre de la hoja a leer.
            output_path: Ruta del archivo de salida (CSV).

            indices: Lista de índices de las columnas a las que se aplicará el forward fill.
        
        Returns:
            Mensaje indicando que el archivo fue procesado y guardado.
        """
        if not self.excel:
            print("No hay ningún archivo Excel abierto.")
            return None

        # Leer la hoja especificada desde el archivo Excel previamente abierto
        df = self.excel.parse(sheet_name)

        # Convertir los índices en una lista de enteros
        indices = [int(i) for i in indices]
        print(f'indices {indices}')

        # Obtener los nombres de las columnas usando los índices
        columnas = [df.columns[i] for i in indices]

        # Reemplazar cadenas vacías ('') en las columnas especificadas por NaN
        df[columnas] = df[columnas].replace(to_replace=r'^\s*$', value=np.nan, regex=True)

        # Crear una máscara de filas que ya están diligenciadas (al menos un valor no nulo en las columnas seleccionadas)
        mask = df[columnas].notna().any(axis=1)

        # Para las filas diligenciadas, completar las celdas faltantes con la cadena "NA"
        df.loc[mask, columnas] = df.loc[mask, columnas].fillna("NA")

        # Para las filas no diligenciadas, aplicar forward fill en las columnas seleccionadas
        df.loc[~mask, columnas] = df.loc[~mask, columnas].ffill()
        
        # Reemplazar cadenas vacías ('') solo en las columnas especificadas por NaN
        df[columnas] = df[columnas].replace(to_replace=r'^\s*$', value=np.nan, regex=True)

        # Aplicar el método 'ffill' solo a las columnas seleccionadas
        df[columnas] = df[columnas].ffill()

        # Guardar el DataFrame actualizado en formato CSV
        df.to_csv(output_path, index=False, encoding='utf-8', lineterminator='\r\n')

        return f"Archivo procesado y guardado en: {output_path}"


if __name__ == "__main__":
    libreria = LibreriaPandas()

    # Prueba de detección de codificación de un CSV
    print("Testing 'Detectar codificacion':")
    encoding = libreria.detectar_codificacion("ruta_del_archivo.csv")
    print(f"Codificación detectada: {encoding}")

    # Prueba de apertura del Excel
    print("\nTesting 'Abrir Excel':")
    resultado_abrir = libreria.abrir_excel("ruta_del_archivo.xlsx")
    print(resultado_abrir)

    # Prueba de completar datos en una hoja específica y guardar como CSV
    print("\nTesting 'Completar Datos':")
    resultado_proceso = libreria.leer_y_completar_datos("Hoja1", "salida.csv", [0, 2])
    print(resultado_proceso)

    # Prueba de cierre del Excel
    print("\nTesting 'Cerrar Excel':")
    resultado_cerrar = libreria.cerrar_excel()
    print(resultado_cerrar)

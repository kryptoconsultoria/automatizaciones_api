import pdfplumber
import pandas as pd
from robot.api.deco import library, keyword

@library
class LibreriaPDF:
    def __init__(self):
        self.pdf = None

    @keyword("Abrir PDF")
    def abrir_pdf(self,ruta_pdf):
        """
        Abre un archivo PDF y lo almacena en la instancia.

        Args:
            ruta_pdf: Ruta del archivo PDF.

        Returns:
            Mensaje confirmando la apertura del PDF.
        """
        try:
            self.pdf = pdfplumber.open(ruta_pdf)
            return f"PDF abierto: {ruta_pdf}"
        except Exception as e:
            return f"Error al abrir el PDF: {e}"

    @keyword("Cerrar PDF")
    def cerrar_pdf(self):
        """
        Cierra el archivo PDF previamente abierto.

        Returns:
            Mensaje confirmando el cierre del PDF.
        """
        if self.pdf:
            self.pdf.close()
            self.pdf = None
            return "PDF cerrado correctamente."
        return "No hay ningún PDF abierto para cerrar."

    @keyword("Extraer Texto")
    def extraer_texto(self, numero_pagina=0):
        """
        Extrae el texto de una página específica del PDF previamente abierto.

        Args:
            numero_pagina: Índice de la página a extraer (0 basado).

        Returns:
            Texto extraído de la página o un mensaje si la página no existe o no hay PDF abierto.
        """
        if not self.pdf:
            return "No hay ningún PDF abierto."

        if 0 <= numero_pagina < len(self.pdf.pages):
            page = self.pdf.pages[numero_pagina]
            return page.extract_text() or "No se encontró texto en la página."
        return f"El número de página {numero_pagina + 1} está fuera del rango del documento."

    def __recortar_pagina(self, pagina):
        """
        Método privado para recortar una página usando ciertos encabezados y pies de página.
        """
        palabras = pagina.extract_words()
        encabezados_validos = {"accionista", "accionistas"}
        pies_validos = {"total", "totales"}

        encabezado = next((w for w in palabras if w['text'].strip().lower() in encabezados_validos), None)
        pie = next((w for w in reversed(palabras) if w['text'].strip().lower() in pies_validos), None)

        x0, x1 = 0, pagina.width
        y0 = max(encabezado['top'] - 5, 0) if encabezado else 0
        y1 = min(pie['bottom'] + 5, pagina.height) if pie else pagina.height

        return pagina.crop((x0, y0, x1, y1))
    
    @keyword("Contar Paginas")    
    def contar_paginas(self):
        """
        Extrae la cantidad de páginas del pdf.

        Returns:
            Numero de paginas para el formato 2276.
        """
        return  len(self.pdf.pages)


    @keyword("Extraer Tablas")
    def extraer_tablas(self, numero_pagina, numero_tabla):
        """
        Extrae una tabla específica de una página del PDF previamente abierto.

        Args:
            numero_pagina: Índice de la página a extraer (0 basado).
            numero_tabla: Número de tabla a extraer.

        Returns:
            Diccionario con la tabla extraída o un mensaje si no se encuentra la tabla o el PDF no está abierto.
        """
        if not self.pdf:
            return "No hay ningún PDF abierto."

        if 0 <= numero_pagina < len(self.pdf.pages):
            pagina = self.pdf.pages[numero_pagina]
            # pagina = self.__recortar_pagina(pagina)  # Uncomment if cropping is needed

            configuracion_tabla = {
                "vertical_strategy": "text",
                "horizontal_strategy": "text"
            }

            tablas = pagina.extract_tables(configuracion_tabla)
            if tablas and numero_tabla < len(tablas):
                df = pd.DataFrame(tablas[numero_tabla][1:], columns=tablas[numero_tabla][0])
                # Exportar a CSV
                df.to_csv("tabla_exportada.csv", index=False, encoding='utf-8-sig')  # nombre del archivo y sin índice
            return f"No se encontró la tabla número {numero_tabla} en la página {numero_pagina + 1}."
        return f"El número de página {numero_pagina + 1} está fuera del rango del documento."
    



if __name__ == "__main__":
    # Ejemplo de uso independiente (para pruebas)
    libreria = LibreriaPDF()
    
    ruta_pdf = "C:\\Users\\Krypto\\PycharmProjects\\automatizaciones_api\\medios_distritales\\insumos\\Rete_ICA\\4. Kconsultoria rte ica presentado IV Bim 2023.pdf"
    
    print("Testing 'Abrir PDF':")
    print(libreria.abrir_pdf(ruta_pdf))
    print(libreria.contar_paginas())

    #print("Testing 'Pasar a base 64':")
    #print(libreria.base_64(ruta_pdf))

    print("\nTesting 'Extraer Texto' en la página 1:")
    print(libreria.extraer_texto(0))

    #print("\nTesting 'Extraer Tablas' en la página 1:")
    #print(libreria.extraer_tablas(0, 0))


    # print("\nTesting 'Cerrar PDF':")
    # print(libreria.cerrar_pdf())

    libreria.cerrar_pdf()

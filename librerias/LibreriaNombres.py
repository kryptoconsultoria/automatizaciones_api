import re
from typing import Tuple,Dict
from robot.api.deco import library, keyword
from typing import Dict

@library
class LibreriaNombres:

    @keyword("Separar Nombres y Apellidos")
    def separar_nombres_apellidos(self,nombre_completo: str) -> Tuple[str, str]:
        # Tokens especiales que se deben unir
        special_tokens = {
            'da', 'de', 'del', 'la', 'las', 'los',
            'mac', 'mc', 'van', 'von', 'y', 'i',
            'san', 'santa'
        }

        tokens = nombre_completo.strip().split()
        names = []
        prev = ""

        for token in tokens:
            lower = token.lower()
            if lower in special_tokens:
                prev += token + " "
            else:
                names.append((prev + token).strip())
                prev = ""

        num = len(names)
        nombres = ""
        apellidos = ""

        if num == 0:
            pass
        elif num == 1:
            nombres = names[0]
        elif num == 2:
            nombres, apellidos = names
        elif num == 3:
            nombres = names[0]
            apellidos = f"{names[1]} {names[2]}"
        elif num == 4:
            nombres = f"{names[0]} {names[1]}"
            apellidos = f"{names[2]} {names[3]}"
        else:
            nombres = f"{names[0]} {names[1]}"
            apellidos = " ".join(names[2:])

        # Transformar a ‘Title Case’ asegurando compatibilidad con UTF‑8
        nombres = nombres.title()
        apellidos = apellidos.title()
        return nombres, apellidos
    
    @keyword("Separar Nombres Completo")
    def separar_nombre_completo(self, full_name: str) -> Tuple[str, str, str, str, bool]:
        """
        Separa un nombre completo en apellido paterno, apellido materno, primer nombre,
        segundo nombre y un flag de validación.
        """
        # Lista de tokens especiales que se deben unir con la siguiente palabra
        special_tokens = {
            'DA', 'DE', 'DEL', 'LA', 'LAS', 'LOS',
            'MAC', 'MC', 'VAN', 'VON', 'Y', 'I',
            'SAN', 'SANTA'
        }

        tokens = full_name.strip().split()
        parts = []
        buffer = []

        # Unir tokens especiales al siguiente
        for t in tokens:
            upper_t = t.upper()
            if buffer and upper_t not in special_tokens:
                buffer.append(t)
                parts.append(" ".join(buffer))
                buffer = []
            elif upper_t in special_tokens:
                buffer.append(t)
            else:
                parts.append(t)

        # Si quedó buffer, agregarlo como parte independiente
        if buffer:
            parts.append(" ".join(buffer))

        # Inicializar campos
        apellido_paterno = ''
        apellido_materno = ''
        primer_nombre = ''
        segundo_nombre = ''
        validar = True
        n = len(parts)

        if n == 0:
            # Datos vacíos
            validar = False
        elif n == 1:
            # Sólo un elemento: considerado primer nombre
            primer_nombre = parts[0]
            validar = False
        elif n == 2:
            # Un apellido y un nombre
            apellido_paterno, primer_nombre = parts
            validar = False
        elif n == 3:
            # Un nombre y dos apellidos
            primer_nombre, apellido_paterno, apellido_materno = parts
            validar = True
        elif n == 4:
            # Dos apellidos y dos nombres
            apellido_paterno, apellido_materno, primer_nombre, segundo_nombre = parts
            validar = False
        else:
            # Más de 4: asignación tentativa y marcar para revisar
            apellido_paterno = f"{parts[0]} {parts[1]}"
            apellido_materno = parts[2]
            primer_nombre = parts[3]
            segundo_nombre = " ".join(parts[4:])
            validar = False

        # Retornar una tupla en lugar de un dict
        return apellido_paterno, apellido_materno, primer_nombre, segundo_nombre, validar



# Ejemplos de uso
if __name__ == "__main__":
    libreria = LibreriaNombres()

    nombre = "claudia patrica perez"
    nom, ape = libreria.separar_nombres_apellidos(nombre)
    print(f"Input: {nombre!r}")
    print(f"  Nombres:   {nom!r}")
    print(f"  Apellidos: {ape!r}")
    print("-" * 30)

    nombre = " VERA DIAZ CRISTOPHER"
    resultado = libreria.separar_nombre_completo(nombre)
    print(resultado)

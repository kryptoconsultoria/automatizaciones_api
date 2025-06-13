import re
from typing import Tuple,Dict
from robot.api.deco import library, keyword

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
    
    from typing import Dict

def separar_nombre_completo(full_name: str) -> Dict[str, str]:
    # Lista de tokens especiales que se deben unir con la siguiente palabra
    special_tokens = {'DA', 'DE', 'DEL', 'LA', 'LAS', 'LOS', 'MAC', 'MC', 'VAN', 'VON', 'Y', 'I', 'SAN', 'SANTA'}

    # Separar por espacios y limpiar
    tokens = full_name.strip().split()
    names = []
    prev = ""

    for token in tokens:
        upper_token = token.upper()
        if upper_token in special_tokens:
            prev += token + " "
        else:
            names.append((prev + token).strip())
            prev = ""

    apellido_paterno = ''
    apellido_materno = ''
    primer_nombre = ''
    segundo_nombre = ''
    validar_name = True

    num_nombres = len(names)

    if num_nombres == 0:
        pass
    elif num_nombres == 1:
        apellido_paterno = names[0]
    elif num_nombres == 2:
        apellido_paterno = names[0]
        primer_nombre = names[1]
    elif num_nombres == 3:
        apellido_paterno = names[0]
        apellido_materno = names[1]
        primer_nombre = names[2]
    elif num_nombres == 4:
        apellido_paterno = names[0]
        apellido_materno = names[1]
        primer_nombre = names[2]
        segundo_nombre = names[3]
        validar_name = False
    else:
        apellido_paterno = f"{names[0]} {names[1]}"
        apellido_materno = names[2]
        primer_nombre = names[3]
        segundo_nombre = " ".join(names[4:])
        validar_name = False

    return {
        'apellido_paterno': apellido_paterno,
        'apellido_materno': apellido_materno,
        'primer_nombre': primer_nombre,
        'segundo_nombre': segundo_nombre,
        'validar_name': validar_name
    }



# Ejemplos de uso
if __name__ == "__main__":
    libreria = LibreriaNombres()

    nombre = "claudia patrica perez"
    nom, ape = libreria.separar_nombres_apellidos(nombre)
    print(f"Input: {nombre!r}")
    print(f"  Nombres:   {nom!r}")
    print(f"  Apellidos: {ape!r}")
    print("-" * 30)

    nombre = "MARTINEZ GOMEZ JUAN DEl holmo"
    resultado = separar_nombre_completo(nombre)

    for k, v in resultado.items():
        print(f"{k}: {v}")

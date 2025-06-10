import re

# Tokens especiales que forman parte de apellidos compuestos
special_tokens = {"da", "de", "del", "la", "las", "los", "mac", "mc", "van", "von", "y", "i", "san", "santa"}

def tokenize_parts(name_str: str):
    """
    Tokeniza una cadena, agrupando tokens especiales (e.g., 'de', 'la') con el token siguiente.
    """
    tokens = name_str.strip().split()
    parts = []
    prev = []
    for token in tokens:
        if token.lower() in special_tokens:
            prev.append(token)
        else:
            if prev:
                # Agrupa tokens especiales con el token actual
                combined = " ".join(prev + [token])
                parts.append(combined)
                prev = []
            else:
                parts.append(token)
    return parts


def split_full_name(full_name: str):
    """
    Separa nombres y apellidos en formato invertido sin coma:
    'Apellido1 Apellido2 Nombre1 Nombre2...'
    Devuelve primero los nombres y luego los apellidos.
    """
    parts = tokenize_parts(full_name)
    # Si no hay al menos un apellido y un nombre, retornamos el completo como nombre
    if len(parts) < 2:
        return full_name.title(), ""

    # Tomar los dos primeros tokens como apellidos, el resto como nombres
    apellido_parts = parts[:2]
    nombre_parts = parts[2:]

    nombre = " ".join(nombre_parts).title()
    apellido = " ".join(apellido_parts).title()
    return nombre, apellido


if __name__ == "__main__":
    ejemplos = [
        "Fernández García María del Carmen",
        "Pérez Juan",
        "García Díaz Ana María",
        "De la Cruz José Luis"
    ]

    for nombre in ejemplos:
        n, a = split_full_name(nombre)
        print(f"Original: {nombre}\nNombres: {n}\nApellidos: {a}\n{'-'*40}")
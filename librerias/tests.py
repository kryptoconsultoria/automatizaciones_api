import pandas as pd

def split_full_name(full_name):
    # separar el nombre completo en espacios
    tokens = full_name.strip().split()
    # lista donde se guardan las "palabras" del nombre
    names = []
    # palabras de apellidos (y nombres) compuetos
    special_tokens = {'da', 'de', 'del', 'la', 'las', 'los', 'mac', 'mc',
                      'van', 'von', 'y', 'i', 'san', 'santa'}
    
    prev = ""
    for token in tokens:
        token_lower = token.lower()
        if token_lower in special_tokens:
            prev += f"{token} "
        else:
            names.append(prev + token)
            prev = ""
    
    num_nombres = len(names)
    nombres = ""
    apellidos = ""
    
    if num_nombres == 0:
        nombres = ""
    elif num_nombres == 1:
        nombres = names[0]
    elif num_nombres == 2:
        nombres = names[0]
        apellidos = names[1]
    elif num_nombres == 3:
        apellidos = f"{names[0]} {names[1]}"
        nombres = names[2]
    else:
        # para 4 o más "palabras" en el nombre
        apellidos = f"{names[0]} {names[1]}"
        # los nombres quedan de la tercera palabra en adelante
        nombres = " ".join(names[2:])
    
    # convertir a mayúsculas de título (capitalizar cada palabra)
    nombres = nombres.title()
    apellidos = apellidos.title()
    
    return nombres, apellidos


if __name__ == "__main__":
    # 1) Carga tu archivo Excel (cambia la ruta y nombre según corresponda)
    df = pd.read_excel("nombresrues.xlsx")

    df['nombre_completo'] = df['nombre_completo'].fillna('')
    
    # 2) Aplica la función a cada fila de la columna 'nombre_completo'
    df[['nombres', 'apellidos']] = df['nombre_completo'] \
        .apply(lambda x: pd.Series(split_full_name(x)))
    
    # 3) Guarda el resultado
    df.to_excel("tus_datos_con_nombres_y_apellidos.xlsx", index=False)
    
    print("Listo: columnas 'nombres' y 'apellidos' agregadas.")
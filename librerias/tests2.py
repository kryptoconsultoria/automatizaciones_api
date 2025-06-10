import os

for root, _, files in os.walk("."):
    for file in files:
        if file.endswith(".py"):
            path = os.path.join(root, file)
            try:
                with open(path, encoding="utf-8") as f:
                    f.read()
            except UnicodeDecodeError:
                print(f"Error en: {path}")

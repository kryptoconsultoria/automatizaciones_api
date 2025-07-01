import spacy
from robot.api.deco import library, keyword
from pathlib import Path 


BASE_DIR = Path(__file__).resolve().parent
FULL_RUTA = BASE_DIR / '..' /'modelos'/'model-best'

@library
class ModeloDirecciones:
    def __init__(self):
        """
        Inicializa el modelo de NLP con la ruta especificada.
        
        Args:
            model_path: Ruta al modelo de spaCy entrenado
        """
        self.nlp = spacy.load(FULL_RUTA)
    
    @keyword('Extraer Entidades')
    def extraer_entidades(self, texto, significado=None):
        """
        Procesa el texto con spaCy y extrae las entidades.
        Si se especifica 'significado', filtra solo las entidades con ese label.
        
        Args:
            texto: Texto a procesar
            significado: Label de entidad a buscar (opcional)
            
        Returns:
            Lista de tuplas (texto_entidad, label, índice_inicio, índice_fin)
        """
        doc = self.nlp(texto)
        resultado = []
        
        for ent in doc.ents:
            if significado is None or ent.label_ == significado:
                resultado.append((ent.text, ent.label_, ent.start, ent.end))
                
        return resultado
    
    @keyword('Reemplazar Entidades')
    def reemplazar_entidades(self, texto, entidades_reemplazar, nuevas_palabras):
        """
        Reemplaza en el texto las entidades especificadas por nuevas palabras.
        
        Args:
            texto: Texto original
            entidades_reemplazar: Lista de tuplas (texto, label, inicio, fin)
            nuevas_palabras: Lista de palabras nuevas para reemplazar
            
        Returns:
            Texto con las entidades reemplazadas
        """
        doc = self.nlp(texto)
        tokens = [(token.text, token.whitespace_) for token in doc]
        
        # Ordenar entidades de fin a principio para no alterar índices
        entidades_ordenadas = sorted(entidades_reemplazar, key=lambda x: x[2], reverse=True)
        
        for i, (ent_text, label, start, end) in enumerate(entidades_ordenadas):
            # Usar la palabra correspondiente o la última disponible
            idx = min(i, len(nuevas_palabras) - 1) if nuevas_palabras else 0
            new_word = nuevas_palabras[idx] if nuevas_palabras else ""
            
            # Mantener el espaciado del último token
            replacement_tuple = (new_word, doc[end-1].whitespace_)
            
            # Reemplazar tokens
            tokens[start:end] = [replacement_tuple]
        
        # Reconstruir texto
        nuevo_texto = "".join(token + whitespace for token, whitespace in tokens)
        return nuevo_texto

    @keyword('Reemplazar Entidades Por Tipo')
    def reemplazar_entidades_por_tipo(self, texto, tipo_entidad, nueva_palabra):
        """
        Reemplaza todas las entidades de un tipo específico por una palabra.
        
        Args:
            texto: Texto original
            tipo_entidad: Tipo de entidad a reemplazar (ej: "DIRECCION")
            nueva_palabra: Palabra de reemplazo
            
        Returns:
            Texto con las entidades del tipo especificado reemplazadas
        """
        entidades = self.extraer_entidades(texto, tipo_entidad)
        return self.reemplazar_entidades(texto, entidades, [nueva_palabra])
    
    @keyword('Reemplazar Multiples Tipos Entidades')
    def reemplazar_multiples_tipos_entidades(self, texto, tipos_y_reemplazos):
        """
        Reemplaza múltiples tipos de entidades con diferentes palabras.
        
        Args:
            texto: Texto original
            tipos_y_reemplazos: Diccionario {tipo_entidad: palabra_reemplazo}
            
        Returns:
            Texto con todas las entidades reemplazadas
        """
        texto_resultado = texto
        
        for tipo, reemplazo in tipos_y_reemplazos.items():
            texto_resultado = self.reemplazar_entidades_por_tipo(
                texto_resultado, tipo, reemplazo)
                
        return texto_resultado
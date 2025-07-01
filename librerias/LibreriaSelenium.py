from seleniumbase import SB
from robot.api.deco import keyword
import time

class LibreriaSelenium:
    """
    Biblioteca personalizada que integra SeleniumBase con Robot Framework utilizando la clase SB.
    Se definen keywords para interactuar con la web mediante selectores XPath.
    """
    ROBOT_LIBRARY_SCOPE = 'GLOBAL'
    
    def __init__(self,screenshoot_root_directory='../screenshots/'):
        self.sb = None
        self._sb_context = None
        self.screenshoot_root_directory=screenshoot_root_directory

    @keyword("Abrir Navegador")
    def open_browser(self, url, browser="chrome", headless=False, uc=False, test=True):
        """
        Abre un navegador y navega a la URL usando SB.
        
        Args:
            url (str): URL a la que navegar.
            browser (str): Navegador a usar (ej. "chrome", "firefox", etc.).
            headless (bool): Ejecutar en modo headless.
            uc (bool): Si True, activa el modo undetected (UC).
            test (bool): Si True, activa el modo test para logs y capturas.
        
        Returns:
            WebDriver: la instancia del driver.
        """
        # Si existe una sesión previa, la cierra.
        if self.sb:
            self.close_browser()
        # Creamos el context manager de SB y entramos en él manualmente
        self._sb_context = SB(uc=uc, test=test, browser=browser, headless=headless)
        self.sb = self._sb_context.__enter__()
        self.sb.open(url)
        return self.sb.driver

    @keyword("Abrir Navegador con Reconexión")
    def open_browser_with_reconnect(self, url, reconnect_attempts=3, browser="chrome", headless=True, uc=True, test=True):
        """
        Abre el navegador en modo undetected (UC) y utiliza el método uc_open_with_reconnect
        para abrir la URL con un número de reintentos especificado.
        
        Args:
            url (str): URL a navegar.
            reconnect_attempts (int): Número de reintentos (default: 3).
            browser (str): Navegador a usar.
            headless (bool): Ejecutar en modo headless.
            uc (bool): Activa el modo undetected (default: True).
            test (bool): Activa el modo test (para logs y capturas).
        
        Returns:
            WebDriver: la instancia del driver.
        """
        if self.sb:
            self.close_browser()
        self._sb_context = SB(undetectable=uc, test=test, browser=browser, headless=headless)
        self.sb = self._sb_context.__enter__()
        # Usa el método uc_open_with_reconnect con el número de reintentos indicado
        
        self.sb.driver.uc_open_with_reconnect(url, reconnect_attempts)
        return self.sb.driver

    @keyword("Cerrar Navegador")
    def close_browser(self):
        """
        Cierra el navegador y finaliza la sesión.
        """
        if self._sb_context:
            try:
                self._sb_context.__exit__(None, None, None)
            except Exception as e:
                raise Exception(f"Error al cerrar el navegador: {e}")
            finally:
                self.sb = None
                self._sb_context = None

    @keyword("Digitar Texto")
    def type_text(self, xpath, text):
        """
        Escribe texto en un elemento identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del elemento.
            text (str): Texto a escribir.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.type(xpath, text)

    @keyword("Click")
    def click_element(self, xpath):
        """
        Hace clic en un elemento identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.click(xpath)

    @keyword("Esperar por elemento")
    def wait_for_element(self, xpath, timeout=10):
        """
        Espera a que un elemento identificado por XPath sea visible.
        
        Args:
            xpath (str): Selector XPath.
            timeout (int): Tiempo máximo de espera (segundos).
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.wait_for_element_visible(xpath, timeout=timeout)

    @keyword("Tomar pantallazo")
    def take_screenshot(self, name="screenshot"):
        """
        Toma una captura de pantalla.
        
        Args:
            name (str): Nombre base del archivo de la captura.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.save_screenshot(f"{self.screenshoot_root_directory}{name}")

    @keyword("Maximizar Ventana")
    def maximize_window(self):
        """
        Maximiza la ventana del navegador.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.maximize_window()

    @keyword("Obtener Texto")
    def get_text(self, xpath):
        """
        Obtiene el texto de un elemento identificado por XPath.
        
        Args:
            xpath (str): Selector XPath.
            
        Returns:
            str: Texto del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        return self.sb.get_text(xpath)

    @keyword("Obtener Atributo")
    def get_attribute(self, xpath, attribute):
        """
        Obtiene el valor de un atributo de un elemento identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del elemento.
            attribute (str): Nombre del atributo.
            
        Returns:
            str: Valor del atributo.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        return self.sb.get_attribute(xpath, attribute)

    @keyword("Verificar Texto")
    def assert_text(self, text, xpath="//html"):
        """
        Verifica que un texto esté presente en un elemento identificado por XPath.
        
        Args:
            text (str): Texto a verificar.
            xpath (str): Selector XPath del elemento (por defecto, toda la página).
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.assert_text(text, xpath)

    @keyword("Verificar Título")
    def assert_title(self, title):
        """
        Verifica el título de la página.
        
        Args:
            title (str): Título esperado.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.assert_title(title)

    @keyword("Seleccionar Opción")
    def select_option(self, xpath, option):
        """
        Selecciona una opción en un menú desplegable.
        
        Args:
            xpath (str): Selector XPath del elemento desplegable.
            option (str): Texto de la opción a seleccionar.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.select_option_by_text(xpath, option)

    @keyword("Presionar Enter")
    def press_enter(self, xpath):
        """
        Presiona la tecla Enter en un elemento identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.press_enter(xpath)

    @keyword("Resaltar Elemento")
    def highlight_element(self, xpath):
        """
        Resalta un elemento para visualización durante la prueba.
        
        Args:
            xpath (str): Selector XPath del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.highlight(xpath)

    @keyword("Ejecutar JavaScript")
    def execute_script(self, script, *args):
        """
        Ejecuta un fragmento de código JavaScript en la página.
        
        Args:
            script (str): Código JavaScript a ejecutar.
            args: Argumentos opcionales para el script.
            
        Returns:
            Resultado devuelto por el script.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        return self.sb.execute_script(script, *args)

    @keyword("Actualizar Página")
    def refresh_page(self):
        """
        Actualiza (refresca) la página actual.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.refresh_page()

    @keyword("Click Captcha")
    def click_captcha(self):
        """
        Cambia el contexto del driver a un iframe identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del iframe.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.uc_gui_click_captcha()

    

    @keyword("Cambiar a Frame")
    def switch_to_frame(self, xpath):
        """
        Cambia el contexto del driver a un iframe identificado por XPath.
        
        Args:
            xpath (str): Selector XPath del iframe.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.switch_to_frame(xpath)

    @keyword("Volver a Contenido Principal")
    def switch_to_default_content(self):
        """
        Vuelve al contenido principal desde un iframe.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.switch_to_default_content()

    @keyword("Verificar Elemento")
    def assert_element(self, xpath):
        """
        Verifica que un elemento identificado por XPath esté presente y sea visible.
        
        Args:
            xpath (str): Selector XPath del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.assert_element(xpath)

    @keyword("Verificar Elemento No Visible")
    def assert_element_not_visible(self, xpath):
        """
        Verifica que un elemento identificado por XPath NO sea visible.
        
        Args:
            xpath (str): Selector XPath del elemento.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.assert_element_not_visible(xpath)

    @keyword("Verificar Atributo")
    def assert_attribute(self, xpath, attribute, value):
        """
        Verifica que el atributo de un elemento tenga el valor esperado.
        
        Args:
            xpath (str): Selector XPath del elemento.
            attribute (str): Nombre del atributo.
            value (str): Valor esperado.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.assert_attribute(xpath, attribute, value)

    @keyword("Arrastrar y Soltar")
    def drag_and_drop(self, source_xpath, target_xpath):
        """
        Realiza la acción de arrastrar un elemento (origen) y soltarlo sobre otro (destino).
        
        Args:
            source_xpath (str): Selector XPath del elemento origen.
            target_xpath (str): Selector XPath del elemento destino.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.drag_and_drop(source_xpath, target_xpath)

    @keyword("Esperar Por Texto")
    def wait_for_text(self, text, xpath="//html", timeout=10):
        """
        Espera a que un texto aparezca en un elemento identificado por XPath.
        
        Args:
            text (str): Texto a esperar.
            xpath (str): Selector XPath (por defecto, toda la página).
            timeout (int): Tiempo máximo de espera (segundos).
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        self.sb.wait_for_text(text, xpath, timeout=timeout)

    @keyword("Contar Elementos")
    def count_elements(self, xpath):
        """
        Cuenta la cantidad de elementos que coinciden con el selector XPath especificado.
        
        Args:
            xpath (str): Selector XPath a evaluar.
            
        Returns:
            int: Número de elementos encontrados.
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        elements = self.sb.find_elements(xpath)
        return int(len(elements))
    
    @keyword("Abrir Nueva Pestaña")
    def open_new_tab(self, url="about:blank"):
        """
        Abre una nueva pestaña en el navegador y cambia el foco a ella.
        
        Args:
            url (str): URL a cargar en la nueva pestaña (por defecto, about:blank).
        """
        if not self.sb:
            raise Exception("Navegador no iniciado. Usa 'Abrir Navegador'.")
        # Abre una nueva pestaña mediante JavaScript
        self.sb.execute_script("window.open(arguments[0], '_blank');", url)
        # Pequeña espera para asegurarse de que la pestaña se abra correctamente
        time.sleep(1)
        # Cambia el foco a la nueva pestaña
        handles = self.sb.driver.window_handles
        self.sb.driver.switch_to.window(handles[-1])


if __name__ == "__main__":
    libreria = LibreriaSelenium()
    libreria.open_browser_with_reconnect(url='https://muisca.dian.gov.co/WebRutMuisca/DefConsultaEstadoRUT.faces', headless=True)
    libreria.type_text(xpath="//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:numNit']",text='52169357')
    time.sleep(7)
    libreria.click_captcha()
    input()
    time.sleep(7)
    libreria.click_element(xpath="//*[@id='vistaConsultaEstadoRUT:formConsultaEstadoRUT:btnBuscar']")
    libreria.take_screenshot(name='test.png')
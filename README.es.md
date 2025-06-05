[English](./README.md) | [Español](./README.es.md)

# Scripts de Configuración de Modo Predeterminado para Chrome

## 🚀 Descripción General

Este proyecto proporciona scripts de PowerShell para configurar Google Chrome en Windows para que se inicie en un modo específico por defecto: ya sea **Modo Invitado** o **Modo Incógnito**. Esto es útil para asegurar una sesión de navegación limpia automáticamente o para una navegación predeterminada centrada en la privacidad.

Cuando se activa el Modo Incógnito, estos scripts también pueden establecer una URL predeterminada (o múltiples URLs) para que se abran automáticamente. Para el Modo Invitado, aunque se puede especificar una URL predeterminada para los accesos directos, Chrome normalmente abre su página de inicio estándar de Invitado.

Estos scripts modifican la configuración del sistema (accesos directos de Chrome y entradas del Registro de Windows) para lograr este comportamiento persistente.

## 📋 Prerrequisitos

* **Sistema Operativo:** Windows (Diseñado y probado principalmente en Windows 11).
* **Navegador:** Google Chrome instalado.
* **PowerShell:** Disponible por defecto en Windows.

## 🚨 ADVERTENCIAS IMPORTANTES 🚨

* **SE REQUIEREN PRIVILEGIOS DE ADMINISTRADOR:** Todos los scripts **DEBEN** ejecutarse con privilegios de Administrador para modificar la configuración del sistema y el registro.
* **Riesgo de Modificación del Registro:** Editar el Registro de Windows puede ser arriesgado. Cambios incorrectos pueden llevar a inestabilidad del sistema o mal funcionamiento de aplicaciones. Aunque estos scripts están diseñados con cuidado, úsalos bajo tu propio riesgo.
* **Copia de Seguridad Recomendada:** Antes de ejecutar cualquier script de activación por primera vez, se **RECOMIENDA ENCARECIDAMENTE**:
    * Crear un Punto de Restauración del Sistema.
    * Hacer una copia de seguridad de cualquier clave del registro que se vaya a modificar (principalmente relacionada con `HKEY_CLASSES_ROOT\ChromeHTML`). Los scripts de activación intentan hacer una copia de seguridad del comando original que modifican.
* **Úsese Tal Cual:** Estos scripts se proporcionan "tal cual". No se expresan ni implican garantías.
* **Actualizaciones de Chrome:** Futuras actualizaciones de Google Chrome podrían revertir esta configuración o cambiar cómo Chrome maneja las asociaciones. Si esto sucede, puede que necesites volver a ejecutar el script apropiado.

## 🛠️ Configuración Inicial

1.  **Descargar/Ubicar Scripts:**
    * Asegúrate de tener los archivos de script (ej., `Enable-ChromeGuestMode.ps1`, `Disable-ChromeIncognitoWithDefaultURL.ps1`, etc.) en una carpeta dedicada en tu computadora (ej., `C:\MisScripts\ChromeConfig`).
        * **Nota sobre Nombres de Script:** Los nombres de script usados en este README (como `Enable-ChromeIncognitoWithDefaultURL.ps1`) reflejan versiones que incluyen la funcionalidad de URL predeterminada. Si tus archivos de script locales tienen nombres ligeramente diferentes (ej., sin "URL" o "WithDefault"), por favor ajusta los comandos correspondientemente.

2.  **Política de Ejecución de PowerShell:**
    * La política de ejecución de PowerShell de tu sistema podría impedir que los scripts se ejecuten. Para verificar, abre PowerShell como Administrador y ejecuta `Get-ExecutionPolicy`.
    * Si es `Restricted`, necesitarás cambiarla. Una configuración común es `RemoteSigned`. Puedes establecerla para el usuario actual ejecutando lo siguiente en una ventana de PowerShell como Administrador:
        ```powershell
        Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
        ```
        Confirma con `S` (o `Y`) si se te pregunta.
    * Alternativamente, para pruebas, puedes establecerla solo para el proceso actual de PowerShell:
        ```powershell
        Set-ExecutionPolicy RemoteSigned -Scope Process -Force
        ```

3.  **Desbloquear Archivos de Script:**
    * Si descargaste los archivos `.ps1` de internet o copiaste su contenido, Windows podría bloquearlos por razones de seguridad.
    * Haz clic derecho en cada archivo `.ps1`, selecciona "Propiedades".
    * En la pestaña "General", si ves un mensaje de seguridad en la parte inferior que dice "Este archivo proviene de otro equipo y podría bloquearse para ayudar a proteger este equipo...", marca la casilla "Desbloquear", luego haz clic en "Aplicar" y "Aceptar".

## ⚙️ Cómo Usar

**Obligatorio: ¡Todos los scripts deben ejecutarse con privilegios de Administrador!**

Hay dos formas principales de ejecutar los scripts:

**Método 1: Ejecución Directa (Clic Derecho)**
1.  Navega a la carpeta que contiene el script en el Explorador de Archivos.
2.  Haz clic derecho en el archivo `.ps1` deseado.
3.  Selecciona "Ejecutar con PowerShell".
4.  Si el Control de Cuentas de Usuario (UAC) te lo pide, haz clic en "Sí" para otorgar permisos de administrador.
    *(Los scripts incluyen un `Read-Host` al final para mantener la ventana abierta y que puedas ver cualquier mensaje.)*

**Método 2: Vía Consola de PowerShell (Recomendado para ver toda la salida)**
1.  Abre PowerShell como **Administrador**.
    * Busca "PowerShell" en el Menú Inicio.
    * Haz clic derecho en "Windows PowerShell" y selecciona "Ejecutar como administrador".
2.  Navega al directorio donde guardaste tus scripts. Reemplaza la ruta de ejemplo con tu ruta real:
    ```powershell
    cd "C:\ruta\a\tus\scripts"
    ```
3.  Ejecuta el script deseado escribiendo su nombre precedido por `.\`:

---

### Configuración de Modo Invitado
Configura Chrome para que se inicie en Modo Invitado por defecto. El Modo Invitado proporciona una sesión de navegación temporal y aislada que no guarda el historial ni las cookies después de cerrar todas las ventanas de invitado.
*(Nota: Aunque los scripts pueden intentar establecer una URL predeterminada para los accesos directos en Modo Invitado, Chrome típicamente ignora esto y abre su página de inicio estándar de Invitado.)*

* **Para Activar el Modo Invitado por Defecto:**
    *(Asumiendo que tu script se llama `Enable-ChromeGuestMode.ps1` o `Enable-ChromeGuestModeWithDefaultURL.ps1` si intenta establecer una URL)*
    ```powershell
    .\Enable-ChromeGuestMode.ps1
    ```

* **Para Desactivar el Modo Invitado por Defecto (Volver a Normal):**
    ```powershell
    .\Disable-ChromeGuestMode.ps1
    ```

---

### Configuración de Modo Incógnito
Configura Chrome para que se inicie en Modo Incógnito por defecto. El Modo Incógnito evita que Chrome guarde tu historial de navegación, cookies, datos de sitios o información introducida en formularios para esa sesión. Aún puedes acceder a tus marcadores existentes. Estos scripts también permiten establecer una URL predeterminada (o múltiples) para los accesos directos.

* **Para Activar el Modo Incógnito por Defecto (con URL predeterminada):**
    *(Asumiendo que tu script se llama `Enable-ChromeIncognitoWithDefaultURL.ps1` o similar)*
    ```powershell
    .\Enable-ChromeIncognitoWithDefaultURL.ps1
    ```

* **Para Desactivar el Modo Incógnito por Defecto (Volver a Normal):**
    ```powershell
    .\Disable-ChromeIncognitoWithDefaultURL.ps1
    ```

---

### 🔧 Gestionar URLs Predeterminadas (para Scripts de Modo Incógnito)

Los scripts de activación para el Modo Incógnito (ej., `Enable-ChromeIncognitoWithDefaultURL.ps1`) típicamente tienen una variable en la parte superior para establecer una URL predeterminada que se abre cuando Chrome se lanza desde un acceso directo modificado.

**1. Cambiar la URL Predeterminada:**
* Abre el script de activación (ej., `Enable-ChromeIncognitoWithDefaultURL.ps1`) en un editor de texto (como VS Code o Bloc de notas).
* Cerca del inicio del script, encuentra la línea:
    ```powershell
    $DefaultURL = "[https://your-default-homepage.com](https://your-default-homepage.com)"
    ```
* Cambia la URL dentro de las comillas a tu nueva página de inicio predeterminada deseada.
* Guarda el script y vuelve a ejecutarlo (como Administrador) para aplicar la nueva URL predeterminada. Puede que necesites ejecutar primero el script de desactivación si deseas una aplicación limpia de la nueva URL.

**2. Establecer Múltiples URLs Predeterminadas:**
* Chrome puede abrir múltiples URLs pasadas en la línea de comandos; usualmente las abre en pestañas separadas.
* Para establecer múltiples URLs predeterminadas, modifica la variable `$DefaultURL` en el script de activación para incluir todas las URLs, separadas por espacios. Asegúrate de que toda la cadena de URLs esté correctamente entrecomillada si se maneja como un solo string de argumento para Chrome, o simplemente enuméralas separadas por espacios directamente después del flag de modo.
* Ejemplo:
    ```powershell
    # Para lanzar múltiples URLs específicas con --incognito desde accesos directos
    # La lógica de modificación de accesos directos del script establecería argumentos como: --incognito "[https://pagina1.com](https://pagina1.com)" "[https://pagina2.com](https://pagina2.com)"
    # Para lograr esto, modificarías la variable $DefaultURL y cómo se usa:
    $DefaultURLs = '"[https://sitio1.ejemplo.com](https://sitio1.ejemplo.com)" "[https://sitio2.ejemplo.com](https://sitio2.ejemplo.com)"' # Una forma de agruparlas
    # Y luego en la parte de modificación de accesos directos:
    # $newArguments = "$IncognitoArgument $DefaultURLs"
    ```
    O, si Chrome las maneja como argumentos separados directamente:
    ```powershell
    $DefaultURL_1 = "[https://sitio1.ejemplo.com](https://sitio1.ejemplo.com)"
    $DefaultURL_2 = "[https://sitio2.ejemplo.com](https://sitio2.ejemplo.com)"
    # Y en la modificación de accesos directos:
    # $newArguments = "$IncognitoArgument `"$DefaultURL_1`" `"$DefaultURL_2`""
    ```
    *Nota: La implementación exacta para múltiples URLs podría requerir ajustar la línea `$newArguments` en la sección "Modificar Accesos Directos" del script de activación para pasar correctamente múltiples URLs a `chrome.exe`.*

**3. Desconfigurar/Eliminar la URL Predeterminada (Lanzar Incógnito a la Página de Nueva Pestaña):**
* **Método A: Editar el Script**
    * Abre el script de activación (ej., `Enable-ChromeIncognitoWithDefaultURL.ps1`).
    * Encuentra la línea `$DefaultURL`.
    * Cámbiala a una cadena vacía:
        ```powershell
        $DefaultURL = ""
        ```
    * Guarda el script.
    * Ejecuta primero el script de desactivación para limpiar la configuración anterior.
    * Luego ejecuta el script de activación modificado. Ahora, los accesos directos deberían abrir el modo Incógnito en su Página de Nueva Pestaña predeterminada.
* **Método B: Usar una Versión del Script Sin Lógica de URL**
    * Si tienes una versión del script de activación que *solo* establece el flag `--incognito` y no incluye ninguna lógica de `$DefaultURL` (ej., un script llamado `Enable-ChromeIncognito.ps1`), puedes ejecutar ese después de desactivar cualquier versión que establezca URLs.

---

## ℹ️ Detalles del Script (Qué hacen)

* **Scripts de Activación:**
    * Modifican los accesos directos de Google Chrome (Escritorio, Menú Inicio) para añadir el flag de línea de comandos necesario (`--guest` o `--incognito`). Para el modo Incógnito, también se puede añadir una URL predeterminada (o múltiples) para los accesos directos.
    * Modifican las entradas del Registro de Windows para `ChromeHTML` (manejando protocolos `http`/`https` y asociaciones de archivos `.html`) para incluir el flag apropiado (`--guest` o `--incognito`). **Nota:** La URL predeterminada *no* se añade a estos comandos del registro, asegurando que al hacer clic en enlaces específicos se abran *esos enlaces* en el modo elegido, no la página de inicio predeterminada.
    * Los scripts de activación hacen una copia de seguridad del comando original del registro que modifican. Esta copia se guarda en `HKEY_CURRENT_USER\Software\Chrome[ModeName]Helper` (ej., `ChromeIncognitoModeHelper` o `ChromeGuestModeHelper`).

* **Scripts de Desactivación:**
    * Eliminan los flags de línea de comandos (y cualquier URL predeterminada para el modo Incógnito) de los accesos directos de Chrome.
    * Restauran el comando original en el Registro de Windows, principalmente usando la copia de seguridad creada por el script de activación. Si no se encuentra la copia de seguridad, intenta eliminar manualmente los flags conocidos.

## ⚠️ Solución de Problemas

* **"No pasa nada" / La ventana se cierra inmediatamente:**
    * Asegúrate de estar ejecutando el script desde una **consola de PowerShell como Administrador** (Método 2 anterior). Esto mantendrá la ventana abierta y mostrará cualquier mensaje o error.
    * Verifica tu **Política de Ejecución** de PowerShell.
    * **Desbloquea** los archivos de script si fueron descargados.
* **Errores durante la ejecución:**
    * Verifica que estás ejecutando PowerShell **como Administrador**.
    * Asegúrate de que el contenido del script sea una copia exacta del código proporcionado y no esté corrupto.
    * Verifica que Google Chrome esté instalado en una ubicación estándar.
* **Accesos directos de la barra de tareas no se actualizan:** Si los accesos directos anclados a la barra de tareas no reflejan los cambios inmediatamente, intenta desanclar Chrome de la barra de tareas y luego volver a anclarlo desde el acceso directo (ya modificado) del Menú Inicio.

## ⚖️ Descargo de Responsabilidad

Estos scripts se proporcionan para uso educativo y personal. Modificar la configuración del sistema, especialmente el Registro de Windows, conlleva riesgos inherentes. El autor o proveedor de estos scripts no se responsabiliza por ningún daño o pérdida de datos que pueda ocurrir por su uso. **Úsalos bajo tu propio riesgo y asegúrate de haber hecho una copia de seguridad de los datos importantes y configuraciones del sistema.**

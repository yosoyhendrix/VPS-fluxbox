# VPS-fluxbox-
Script de Instalación y Configuración de Escritorio Ligero (Debian 12)
Este script se enfoca en instalar Fluxbox, ROX-Filer, y Firefox-ESR, junto con las configuraciones necesarias para que cualquier usuario pueda iniciar su propia sesión VNC con TigerVNC en Debian 12. No se configurará VNC como un servicio global, sino que cada usuario lo activará con vncserver.

## instalación 
## 1 Descage el script 
```
https://raw.githubusercontent.com/yosoyhendrix/VPS-fluxbox-/refs/heads/main/install_custom_desktop.sh
```
## 2 Dale permiso de ejecución
```
chmod +x install_custom_desktop.sh
```
## 3 Ejecutar como usuario root 
```
sudo ./install_custom_desktop.sh
```
## 4 Sigue las instrucciones Post-Instalación:
   * El script reiniciará tu VPS automáticamente al finalizar.
   * Para cada usuario (incluido root) que quieras que tenga acceso VNC:
     * Inicia sesión en la VPS como ese usuario (vía SSH).
     * Ejecuta vncpasswd y establece una contraseña para VNC. ¡Haz esto también para el usuario root si quieres que root pueda iniciar una sesión VNC!
   * Para iniciar una sesión VNC, ese usuario deberá ejecutar: vncserver :1 (o el número de display que prefiera, si :1 ya está en uso).
   * Asegúrate de que los puertos VNC (5901-5910/TCP) estén abiertos en el firewall de tu proveedor de VPS además de UFW.
Este script te dará la flexibilidad que buscas, permitiendo que cada usuario gestione su propia sesión VNC, lo cual es más seguro y adaptable a entornos multiusuario.

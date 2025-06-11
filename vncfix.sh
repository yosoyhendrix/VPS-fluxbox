#!/bin/bash

# Script para eliminar TODAS las configuraciones de VNCServer (TigerVNC)
# del sistema y de todos los usuarios.
# Deja el software VNC instalado pero sin configuraciones, como una instalación limpia.

# --- Configuración ---
LOG_FILE="/var/log/vnc_clean_reinstall_config.log"
DATE=$(date +%Y%m%d_%H%M%S)

# --- Funciones de Ayuda ---

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_message "Este script debe ejecutarse como root o con sudo."
        echo "Por favor, ejecuta: sudo ./$(basename "$0")"
        exit 1
    fi
}

# --- Inicio del Script ---

check_root
log_message "Iniciando la eliminación de TODAS las configuraciones de VNCServer (TigerVNC)."
log_message "El software VNC Server NO será desinstalado."
log_message "Los detalles de la ejecución se guardarán en $LOG_FILE"

# 1. Detener cualquier instancia de VNCServer que pueda estar corriendo
log_message "Deteniendo cualquier servicio de VNCServer activo..."
# Detener servicios gestionados por Systemd
sudo systemctl stop vncserver@*.service >> "$LOG_FILE" 2>&1

# Matar procesos Xvnc residuales que podrían no ser gestionados por systemd
# Esto es importante para liberar los archivos de configuración
pgrep -f "Xvnc" | while read -r PID; do
    log_message "Matando proceso Xvnc con PID: $PID"
    sudo kill -9 "$PID" >> "$LOG_FILE" 2>&1
done
log_message "Procesos VNCServer detenidos y/o terminados."

# 2. Eliminar archivos de servicio Systemd de VNCServer (si existen)
log_message "Eliminando archivos de servicio Systemd de VNCServer..."
VNC_SERVICE_FILE="/etc/systemd/system/vncserver@.service"
if [ -f "$VNC_SERVICE_FILE" ]; then
    sudo systemctl disable vncserver@*.service >> "$LOG_FILE" 2>&1
    sudo rm -f "$VNC_SERVICE_FILE" >> "$LOG_FILE" 2>&1
    log_message "Archivo '$VNC_SERVICE_FILE' eliminado."
else
    log_message "No se encontró el archivo de servicio '$VNC_SERVICE_FILE'."
fi

# Recargar Systemd para que los cambios surtan efecto
sudo systemctl daemon-reload >> "$LOG_FILE" 2>&1
sudo systemctl reset-failed >> "$LOG_FILE" 2>&1
log_message "Systemd recargado y estado de servicios reseteado."

# 3. Eliminar directorios de configuración de usuario (.vnc)
log_message "Buscando y eliminando directorios '.vnc' de todos los usuarios (incluido root)..."

# Eliminar el directorio .vnc del usuario root
if [ -d "/root/.vnc" ]; then
    log_message "Eliminando /root/.vnc..."
    sudo rm -rf "/root/.vnc" >> "$LOG_FILE" 2>&1
    log_message "/root/.vnc eliminado."
else
    log_message "No se encontró /root/.vnc."
fi

# Eliminar el directorio .vnc de todos los usuarios en /home/
# Esto cubre cualquier usuario estándar que pueda haber creado una sesión VNC.
for user_home in /home/*; do
    # Asegúrate de que sea un directorio de usuario real y no un enlace simbólico roto o algo más
    if [ -d "$user_home" ] && [ -d "$user_home/.vnc" ]; then
        user=$(basename "$user_home")
        log_message "Eliminando $user_home/.vnc para el usuario '$user'..."
        sudo rm -rf "$user_home/.vnc" >> "$LOG_FILE" 2>&1
        log_message "$user_home/.vnc eliminado."
    else
        user=$(basename "$user_home")
        log_message "No se encontró $user_home/.vnc para el usuario '$user' o no es un directorio de usuario válido."
    fi
done

log_message "Directorios '.vnc' de todos los usuarios eliminados."

# 4. Eliminar el esqueleto de configuración de VNC de /etc/skel
log_message "Eliminando el esqueleto de configuración de VNC de /etc/skel/..."
SKEL_VNC_DIR="/etc/skel/.vnc"
if [ -d "$SKEL_VNC_DIR" ]; then
    sudo rm -rf "$SKEL_VNC_DIR" >> "$LOG_FILE" 2>&1
    log_message "'$SKEL_VNC_DIR' eliminado. Nuevos usuarios no heredarán configuraciones VNC."
else
    log_message "No se encontró '$SKEL_VNC_DIR'."
fi

# 5. Opcional: Limpiar reglas de firewall de VNC (UFW)
log_message "Verificando y limpiando reglas de firewall de VNC (UFW)..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        log_message "UFW está activo. Eliminando reglas de VNC (puertos 5901-5910/TCP)."
        # Asegúrate de eliminar el rango de puertos que configuraste previamente
        sudo ufw delete allow 5901:5910/tcp >> "$LOG_FILE" 2>&1
        sudo ufw reload >> "$LOG_FILE" 2>&1
        log_message "Reglas de UFW para VNC eliminadas y firewall recargado."
    else
        log_message "UFW no está activo. No se necesitan limpiar reglas de firewall."
    fi
else
        log_message "UFW no está instalado. No se necesitan limpiar reglas de firewall."
fi

log_message "Proceso de limpieza de configuraciones de VNCServer completado."
log_message "--------------------------------------------------------------------------------"
log_message "El software TigerVNC Server permanece instalado, pero todas sus configuraciones (contraseñas, xstartup, etc.) han sido eliminadas."
log_message "Para usar VNC de nuevo, cada usuario deberá ejecutar 'vncpasswd' para establecer una nueva contraseña antes de iniciar 'vncserver'."
log_message "Asegúrate de reconfigurar cualquier firewall externo (de tu proveedor de VPS) si es necesario."
log_message "--------------------------------------------------------------------------------"

exit 0
vncserver :1 -geometry 1024x700 -depth 24

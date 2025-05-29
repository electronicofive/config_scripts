#!/bin/bash

# Directorio donde se encuentran los scripts originales
# Asume que están en el mismo directorio que este script.
# Si no es así, cambia esta variable a la ruta correcta.
SCRIPT_DIR="$(dirname "$0")" 

# Nombres de los scripts originales
CONFIG_IPTABLES_SCRIPT="${SCRIPT_DIR}/port_config/config_iptables.sh"
SET_SHARED_SCRIPT="${SCRIPT_DIR}/port_config/set_shared.sh"
RESTORE_IPTABLES_SCRIPT="${SCRIPT_DIR}/port_config/restore_iptables.sh"
RESTORE_DHCP_SCRIPT="${SCRIPT_DIR}/port_config/restore_dhcp.sh"

# --- Verificación de scripts ---
# Comprueba si los scripts necesarios existen y son ejecutables
check_script() {
    local script_path="$1"
    local script_name=$(basename "$script_path")
    if [[ ! -f "$script_path" ]]; then
        echo "Error: El script '$script_name' no se encontró en '$SCRIPT_DIR'." >&2
        exit 1
    fi
    if [[ ! -x "$script_path" ]]; then
        echo "Error: El script '$script_name' no tiene permisos de ejecución." >&2
        echo "Por favor, ejecuta: chmod +x $script_path" >&2
        exit 1
    fi
}

# --- Función de ayuda ---
usage() {
    echo "Uso: $0 <acción>"
    echo "Acciones disponibles:"
    echo "  config      : Configura las conexiones del servidor para compartir internet"
    echo "  cleanup     : Restaura las configuraciones del DHCP"
    echo ""
    echo "Ejemplo:"
    echo "  $0 config"
    echo "  $0 cleanup" 
    exit 1
}

# --- Verificación de parámetros ---
if [ "$#" -ne 1 ]; then
    echo "Error: Se requiere exactamente un parámetro." >&2
    usage
fi

ACTION="$1"

# --- Lógica Principal ---
case "$ACTION" in
    config)
        echo "== Iniciando acción: config =="
        
        echo "-> Verificando scripts de configuración..."
        check_script "$CONFIG_IPTABLES_SCRIPT"
        check_script "$SET_SHARED_SCRIPT"
        echo "   Scripts OK."

        echo "-> Ejecutando ${CONFIG_IPTABLES_SCRIPT}..."
	echo "     "
        if ! "$CONFIG_IPTABLES_SCRIPT"; then
             echo "Error: Falló la ejecución de ${CONFIG_IPTABLES_SCRIPT}" >&2
             exit 1
        fi
        echo "-> Ejecutando ${SET_SHARED_SCRIPT}..."
	echo "     "
         if ! "$SET_SHARED_SCRIPT"; then
             echo "Error: Falló la ejecución de ${SET_SHARED_SCRIPT}" >&2
             exit 1
        fi

        echo "== Acción 'config' completada =="
        ;;

    cleanup) # Necesita comillas por el espacio
        echo "== Iniciando acción: clean up =="

        echo "-> Verificando scripts de limpieza..."
        check_script "$RESTORE_IPTABLES_SCRIPT"
        check_script "$RESTORE_DHCP_SCRIPT"
        echo "   Scripts OK."

        echo "-> Ejecutando ${RESTORE_IPTABLES_SCRIPT}..."
	echo "   "
        if ! "$RESTORE_IPTABLES_SCRIPT"; then
             echo "Error: Falló la ejecución de ${RESTORE_IPTABLES_SCRIPT}" >&2
             exit 1
        fi
        
        echo "-> Ejecutando ${RESTORE_DHCP_SCRIPT}..."
	echo "   "
        if ! "$RESTORE_DHCP_SCRIPT"; then
             echo "Error: Falló la ejecución de ${RESTORE_DHCP_SCRIPT}" >&2
             exit 1
        fi

        echo "== Acción 'clean up' completada =="
        ;;

    *) # Caso por defecto para parámetros inválidos
        echo "Error: Acción '$ACTION' no reconocida." >&2
        usage
        ;;
esac

exit 0

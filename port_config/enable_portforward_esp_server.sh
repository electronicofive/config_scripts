#!/bin/bash
# Interfaz de salida a internet
INTERNET_IFACE="eth4"
# Interfaz y detalles para el port forwarding
FORWARD_IFACE="eth2"
FORWARD_PORT="80"
HOST_PORT="2025"
TARGET_IP="192.168.40.2"

# Verificar que tenemos una IP válida
if [ -n "$TARGET_IP" ]; then
    echo "Configurando port forwarding del puerto $HOST_PORT al puerto $FORWARD_PORT en $TARGET_IP"
    
    # Verificar si ya existe la regla de port forwarding
    has_prerouting=$(iptables -t nat -L PREROUTING -v | grep "DNAT" | grep "dpt:$HOST_PORT" | grep "to:$TARGET_IP:$FORWARD_PORT")
    
    if [ -z "$has_prerouting" ]; then
        # Regla para redireccionar el tráfico entrante
        iptables -t nat -A PREROUTING -p tcp --dport $HOST_PORT -j DNAT --to-destination $TARGET_IP:$FORWARD_PORT
        echo "Agregada regla PREROUTING para redireccionar puerto $HOST_PORT a $TARGET_IP:$FORWARD_PORT"
        
        # Regla para permitir el tráfico forwarded hacia el servidor
        iptables -A FORWARD -p tcp -d $TARGET_IP --dport $FORWARD_PORT -j ACCEPT
        echo "Agregada regla FORWARD para permitir tráfico hacia $TARGET_IP:$FORWARD_PORT"
    else
        echo "√ La regla de port forwarding ya existe"
    fi
else
    echo "Error: No se pudo obtener la IP del servidor en $FORWARD_IFACE"
fi

# Guardar reglas iptables para que persistan después de reiniciar
echo "Guardando reglas iptables..."
# Verificar si existe iptables-persistent
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
else
    # Crear directorio si no existe
    mkdir -p /etc/iptables
    
    # Guardar reglas
    iptables-save > /etc/iptables/rules.v4
    
    echo "Reglas guardadas en /etc/iptables/rules.v4"
    echo "Para cargarlas automáticamente al iniciar, instala iptables-persistent:"
    echo "sudo apt install iptables-persistent"
fi

echo "=== Configuración de iptables completada ==="
echo "Port forwarding: Puerto $HOST_PORT → $TARGET_IP:$FORWARD_PORT"

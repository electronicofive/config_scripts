#!/bin/bash
# Interfaz de salida a internet
INTERNET_IFACE="eth4"
echo "=== Configuración de reglas iptables para compartir Internet desde $INTERNET_IFACE ==="

# Obtener solo las interfaces eth, excepto la de internet
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep '^eth' | grep -v '^'$INTERNET_IFACE'$')

# Verificar si el forwarding está habilitado
forward_status=$(cat /proc/sys/net/ipv4/ip_forward)
if [ "$forward_status" -ne 1 ]; then
    echo "Habilitando IP forwarding..."
    echo 1 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward=1" > /etc/sysctl.d/99-ipforward.conf
    sysctl -p /etc/sysctl.d/99-ipforward.conf
fi

# Verificar si ya existe regla MASQUERADE para la interfaz de internet
has_masquerade=$(iptables -t nat -L POSTROUTING -v | grep MASQUERADE | grep "$INTERNET_IFACE")
if [ -z "$has_masquerade" ]; then
    echo "Agregando regla MASQUERADE para $INTERNET_IFACE..."
    iptables -t nat -A POSTROUTING -o "$INTERNET_IFACE" -j MASQUERADE
else
    echo "√ Regla MASQUERADE para $INTERNET_IFACE ya existe"
fi

# Configurar reglas para cada interfaz eth
for iface in $interfaces; do
    echo "Procesando interfaz: $iface"
    
    # Verificar si ya existe regla FORWARD para esta interfaz
    has_forward_rule=$(iptables -L FORWARD -v | grep "$iface" | grep "$INTERNET_IFACE")
    
    if [ -z "$has_forward_rule" ]; then
        echo "  Agregando reglas FORWARD para $iface..."
        # Regla para tráfico saliente
        iptables -A FORWARD -i "$iface" -o "$INTERNET_IFACE" -j ACCEPT
        # Regla para tráfico entrante relacionado
        iptables -A FORWARD -i "$INTERNET_IFACE" -o "$iface" -m state --state RELATED,ESTABLISHED -j ACCEPT
    else
        echo "  √ Las reglas FORWARD para $iface ya existen"
    fi
done

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
    echo "Para cargarlas automáticamente al iniciar, se instalará iptables-persistent:"
    echo "sudo apt install iptables-persistent"
    sudo apt install iptables-persistent -y
    if command -v netfilter-persistent &> /dev/null; then
    	netfilter-persistent save
    else
    	echo "Error instalando iptables"
    fi
fi

echo "=== Configuración de iptables completada ==="
echo "Las reglas han sido configuradas y guardadas. Solo las interfaces eth pueden ahora compartir internet a través de $INTERNET_IFACE"

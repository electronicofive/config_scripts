#!/bin/bash

# Interfaz de salida a internet
INTERNET_IFACE="eth4"
echo "=== Revirtiendo configuración de iptables para $INTERNET_IFACE ==="

# Obtener interfaces eth, excepto la de internet
interfaces=$(ip -o link show | awk -F': ' '{print $2}' | grep '^eth' | grep -v '^'$INTERNET_IFACE'$')

# Desactivar IP forwarding
if grep -q "net.ipv4.ip_forward=1" /etc/sysctl.d/99-ipforward.conf 2>/dev/null; then
    echo "Desactivando IP forwarding..."
    echo 0 > /proc/sys/net/ipv4/ip_forward
    echo "net.ipv4.ip_forward=0" > /etc/sysctl.d/99-ipforward.conf
    sysctl -p /etc/sysctl.d/99-ipforward.conf
else
    echo "√ IP forwarding ya estaba desactivado o no fue configurado previamente"
fi

# Eliminar regla MASQUERADE si existe
masq_exists=$(iptables -t nat -L POSTROUTING -v -n --line-numbers | grep MASQUERADE | grep "$INTERNET_IFACE" | awk '{print $1}' | tac)
if [ -n "$masq_exists" ]; then
    echo "Eliminando regla(s) MASQUERADE para $INTERNET_IFACE..."
    for line in $masq_exists; do
        iptables -t nat -D POSTROUTING "$line"
    done
else
    echo "√ No se encontraron reglas MASQUERADE activas para $INTERNET_IFACE"
fi

# Eliminar reglas FORWARD para cada interfaz
for iface in $interfaces; do
    echo "Procesando interfaz: $iface"

    # Eliminar reglas FORWARD con tráfico entrante
    forward_in=$(iptables -L FORWARD -v -n --line-numbers | grep "$iface" | grep "$INTERNET_IFACE" | awk '{print $1}' | tac)
    for line in $forward_in; do
        iptables -D FORWARD "$line"
    done

    # Eliminar reglas FORWARD con tráfico saliente
    forward_out=$(iptables -L FORWARD -n --line-numbers | grep "$INTERNET_IFACE" | grep "$iface" | awk '{print $1}' | tac)
    for line in $forward_out; do
        iptables -D FORWARD "$line"
    done
done

# Guardar reglas iptables si se usaba iptables-persistent
echo "Guardando cambios..."
if command -v netfilter-persistent &> /dev/null; then
    netfilter-persistent save
else
    iptables-save > /etc/iptables/rules.v4
    echo "Reglas actualizadas en /etc/iptables/rules.v4"
fi

echo "=== Reversión de iptables completada ==="
echo "El sistema ha sido restaurado a un estado sin reglas para compartir Internet"

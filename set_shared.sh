#!/bin/bash

# Interfaz a excluir (conexión a internet)
EXCLUDE_INTERFACE="eth4"

# Contador para asignar subredes
subnet_counter=10

# Obtener todas las conexiones Ethernet
while IFS= read -r line; do
    conn=$(echo "$line" | cut -d':' -f1)
    
    # Obtener la interfaz asociada a esta conexión
    iface=$(nmcli -g GENERAL.DEVICES connection show "$conn" 2>/dev/null)
    
    echo "Analizando conexión: '$conn' (interfaz: $iface)"
    
    # Saltar la conexión si es la interfaz de internet
    if [[ "$iface" == "$EXCLUDE_INTERFACE" ]]; then
        echo "Saltando '$conn' porque usa la interfaz $EXCLUDE_INTERFACE (conexión a internet)"
        continue
    fi
    
    # Obtener el método IPv4 actual
    method=$(nmcli -g ipv4.method connection show "$conn")
    
    if [ "$method" != "shared" ]; then
        echo "Cambiando '$conn' a modo 'shared' con IP 192.168.${subnet_counter}.1"
        
        # Modificar la conexión a shared con IP específica
        nmcli connection modify "$conn" \
            ipv4.method shared \
            ipv4.addresses "192.168.${subnet_counter}.1/24"
        
        echo "✓ Conexión '$conn' modificada a método 'shared' con IP 192.168.${subnet_counter}.1"
        
        # Incrementar contador para la siguiente subred
        subnet_counter=$((subnet_counter + 10))
    else
        current_ip=$(nmcli -g ipv4.addresses connection show "$conn")
        echo "La conexión '$conn' ya está en modo 'shared' con IP $current_ip"
        
        # Aún así actualizar la IP si queremos estandarizar
        echo "Actualizando IP a 192.168.${subnet_counter}.1"
        nmcli connection modify "$conn" ipv4.addresses "192.168.${subnet_counter}.1/24"
        
        
        echo "✓ IP actualizada para '$conn'"
        
        # Incrementar contador para la siguiente subred
        subnet_counter=$((subnet_counter + 10))
    fi
done < <(nmcli -t -f NAME,TYPE connection show | grep ethernet)

echo "Configuración completada. Todas las interfaces (excepto $EXCLUDE_INTERFACE) están ahora en modo 'shared'"
echo "Las IPs se han asignado en rangos de 10 en 10 comenzando por 192.168.10.1"

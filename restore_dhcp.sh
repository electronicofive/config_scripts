#!/bin/bash

# Interfaz a excluir (conexión a internet)
EXCLUDE_INTERFACE="eth4"

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
    
    # Verificar si está en modo shared
    method=$(nmcli -g ipv4.method connection show "$conn")
    
    if [[ "$method" == "shared" ]]; then
        echo "Restaurando '$conn' a configuración automática (DHCP)"
        
        # Restaurar a configuración automática (de fábrica típica)
        nmcli connection modify "$conn" \
            ipv4.method auto \
            ipv4.addresses "" \
            ipv4.gateway "" \
            ipv4.dns "" \
            ipv4.ignore-auto-dns no \
            ipv4.ignore-auto-routes no
        
        echo "✓ Conexión '$conn' restaurada a DHCP"
    else
        echo "La conexión '$conn' no está en modo 'shared', no se modifica"
    fi
done < <(nmcli -t -f NAME,TYPE connection show | grep ethernet)

echo "Restauración completada. Todas las interfaces (excepto $EXCLUDE_INTERFACE) están ahora en modo automático (DHCP)"

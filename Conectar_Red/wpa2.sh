#!/bin/bash

#######################################
# muestras las iterfaces de red
#######################################
mostrar_interfaces() {
    echo "Interfaces de red disponibles y su estado:"
    ip link show
}

#######################################
# cambiar el estado (up/down)
#######################################
cambiar_estado() {
    read -p "Introduce el nombre de la interfaz que quieres modificar: " interfaz
    read -p "¿Deseas ponerla up o down? (up/down): " estado
    sudo ip link set dev "$interfaz" "$estado"
    echo "La interfaz $interfaz ahora está en estado $estado."
    ip link show "$interfaz"
}

#######################################
# conectar a la red, inalambrica o cableada
# para cableada se usa dhclient; para inalámbrica usando iwconfig o wpa_supplicant en caso de tener contraseña.
#######################################
conectar_red() {
    read -p "Introduce la interfaz a usar: " interfaz
    echo "Seleccione el tipo de conexión:"
    echo "1) Cableada"
    echo "2) Inalámbrica"
    read -p "Opción (1/2): " tipo_conexion

    if [[ "$tipo_conexion" == "1" ]]; then
        echo "Conexión cableada seleccionada."
        echo "Obteniendo IP mediante DHCP..."
        sudo dhclient -v "$interfaz"

    elif [[ "$tipo_conexion" == "2" ]]; then
        echo "Conexión inalámbrica seleccionada."
        echo "Escaneando redes disponibles en $interfaz..."
        sudo iwlist "$interfaz" scan | grep "ESSID"
        read -p "Introduce el SSID de la red a la que deseas conectarte: " ssid
        read -p "¿La red tiene contraseña? (s/n): " tiene_pass
        if [[ "$tiene_pass" == "s" ]]; then
            read -s -p "Introduce la contraseña: " password
            echo ""
            # archivo de configuración temporal para wpa_supplicant
            cat <<EOF > wifi.conf
network={
    ssid="$ssid"
    psk="$password"
}
EOF
            echo "Conectando con wpa_supplicant..."
            sudo wpa_supplicant -B -D wext -i "$interfaz" -c wifi.conf
        else
            echo "Conectando sin contraseña usando iwconfig..."
            sudo iwconfig "$interfaz" essid "$ssid"
        fi
        echo "Obteniendo IP mediante DHCP..."
        sudo dhclient -v "$interfaz"
    else
        echo "Opción no válida."
        exit 1
    fi
    echo "Conexión establecida en la interfaz $interfaz."
}

#######################################
# configurar la ip de forma dinamica o estatica y la guarda en /etc/network/interfaces
#######################################
configurar_ip() {
    read -p "Introduce la interfaz a configurar: " interfaz
    echo "Seleccione el tipo de configuración IP:"
    echo "1) Dinámica (DHCP)"
    echo "2) Estática"
    read -p "Opción (1/2): " tipo_ip

    # se respalda la configuración actual, por cualquier cosa
    sudo cp /etc/network/interfaces /etc/network/interfaces.bak

    if [[ "$tipo_ip" == "1" ]]; then
        echo "Configurando IP dinámica para $interfaz..."
        cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto $interfaz
iface $interfaz inet dhcp
EOF

    elif [[ "$tipo_ip" == "2" ]]; then
        read -p "Introduce la dirección IP: " ip
        read -p "Introduce la máscara de red (ej. 255.255.255.0): " mascara
        read -p "Introduce la puerta de enlace: " gateway
        read -p "Introduce los DNS (separados por espacio): " dns
        echo "Configurando IP estática para $interfaz..."
        cat <<EOF | sudo tee /etc/network/interfaces > /dev/null
auto $interfaz
iface $interfaz inet static
    address $ip
    netmask $mascara
    gateway $gateway
    dns-nameservers $dns
EOF
    else
        echo "Opción no válida."
        exit 1
    fi

    echo "Reiniciando el servicio de red para aplicar la configuración..."
    sudo systemctl restart networking
    echo "La configuración se ha guardado permanentemente en /etc/network/interfaces."
}

#######################################
# Menu
#######################################
while true; do
    echo ""
    echo "===== Menú de Configuración de Red ====="
    echo "1) Mostrar interfaces de red"
    echo "2) Cambiar estado de una interfaz (up/down)"
    echo "3) Conectarse a una red (cableada o inalámbrica)"
    echo "4) Configurar IP (DHCP o estática) y guardar configuración"
    echo "5) Salir"
    read -p "Selecciona una opción: " opcion

    case "$opcion" in
        1) mostrar_interfaces ;;
        2) cambiar_estado ;;
        3) conectar_red ;;
        4) configurar_ip ;;
        5) echo "Saliendo..."; exit 0 ;;
        *) echo "Opción no válida, intenta nuevamente." ;;
    esac
done

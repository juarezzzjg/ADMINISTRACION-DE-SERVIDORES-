#!/bin/bash

ayuda() {
    echo "$(basename $0)"
    echo "Crea usuarios en el sistema de forma interactiva."
    echo "Pide el nombre del usuario y una contrasena que cumpla ciertas reglas."
}

echo_error() {
    echo "$1" >&2
}

reportar_error() {
    local mensaje="$1"
    echo_error "$mensaje"
    ayuda
    exit 1
}

test "$1" == "-h" || test "$1" == "--help" && { ayuda; exit; }

MIN_LENGTH=8
REQUIRES_NUMBER=1
REQUIRES_UPPER=1
REQUIRES_LOWER=1
REQUIRES_SPECIAL=1

validar_contrasena() {
    local contrasena="$1"

    # Verifica la longitud mínima
    test "$(echo -n "$contrasena" | wc -c)" -lt "$MIN_LENGTH" && {
        echo "La contrasena debe tener al menos $MIN_LENGTH caracteres."
        return 1
    }

    # Verifica si contiene al menos un número
    test "$REQUIRES_NUMBER" -eq 1 && ! echo "$contrasena" | grep -q '[0-9]' && {
        echo "La contraseña debe contener al menos un número."
        return 1
    }

    # Verifica si contiene al menos una letra mayúscula
    test "$REQUIRES_UPPER" -eq 1 && ! echo "$contrasena" | grep -q '[A-Z]' && {
        echo "La contraseña debe contener al menos una letra mayúscula."
        return 1
    }

    # Verifica si contiene al menos una letra minúscula
    test "$REQUIRES_LOWER" -eq 1 && ! echo "$contrasena" | grep -q '[a-z]' && {
        echo "La contraseña debe contener al menos una letra minúscula."
        return 1
    }

    # Verifica si contiene al menos un carácter especial
    test "$REQUIRES_SPECIAL" -eq 1 && ! echo "$contrasena" | grep -q '[^a-zA-Z0-9]' && {
        echo "La contraseña debe contener al menos un carácter especial."
        return 1
    }

    return 0
}

solicitar_contrasena() {
    while true; do
        read -s -p "Ingrese la contraseña: " contrasena
        echo
        read -s -p "Confirme la contraseña: " confirmacion
        echo

        test "$contrasena" != "$confirmacion" && {
            echo "Las contrasenas no coinciden."
            continue
        }

        validar_contrasena "$contrasena" && break
    done
}

crear_usuario() {
    local usuario
    read -p "Ingrese el nombre del usuario: " usuario

    test "$(id "$usuario" 2>/dev/null)" && reportar_error "El usuario '$usuario' ya existe."

    solicitar_contrasena

    sudo useradd -m "$usuario"
    echo "$usuario:$contrasena" | sudo chpasswd
    echo "Usuario '$usuario' creado exitosamente."
}

crear_usuario

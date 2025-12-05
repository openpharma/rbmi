#!/bin/bash

if [ "$BUILD_ENV" = "local" ]; then
    echo "--- Installing local corporate certs ---"
    mkdir -p /usr/local/share/ca-certificates/
    for cert in /tmp/certs/*; do
        if [ "$(basename "$cert")" != ".gitignore" ] && [ "$(basename "$cert")" != "install_certs.sh" ]; then
            if [[ "$cert" == *.pem ]]; then
                cp "$cert" "/usr/local/share/ca-certificates/$(basename "$cert" .pem).crt"
            else
                cp "$cert" /usr/local/share/ca-certificates/
            fi
        fi
    done
    update-ca-certificates
else
    echo "--- Skipping corporate certs for public build ---"
fi
rm -rf /tmp/certs

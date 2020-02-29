#!/bin/sh -eu

until curl -IsS http://kong:8001/status/ && curl -IsS http://keycloak:8080/; do
  echo
  sleep 1
done

if [ -z "$HOST_IP" ]; then
    echo HOST_IP not defined, will skip setup
    exit 0
fi
echo "Setup for ${HOST_IP}"

#
# Keycloak
#
export PATH=$PATH:${JBOSS_HOME}/bin

kcadm.sh config credentials --server http://keycloak:8080/auth --realm master --user "${KEYCLOAK_USER}" --password "${KEYCLOAK_PASSWORD}"

if [ -z "$(kcadm.sh get realms --fields realm | jq -r '.[] | select(.realm=="application") | .realm')" ]; then
    kcadm.sh create realms -s realm=application -s enabled=true
    echo Created realm application
fi

CLIENT_ID=$(kcadm.sh get clients -r application --fields id,clientId |  jq -r '.[] | select(.clientId=="kong") | .id')
if [ -z "${CLIENT_ID}" ]; then
    CLIENT_ID=$(kcadm.sh create clients --id -r application -s clientId=kong -s enabled=true -s publicClient=false -s redirectUris="[\"http://$HOST_IP:8000/*\"]")
    echo Created client kong in realm application
else
    kcadm.sh update "clients/${CLIENT_ID}" -r application -s redirectUris="[\"http://$HOST_IP:8000/*\"]"
    echo Updated client kong in realm application
fi
SECRET=$(kcadm.sh get "clients/${CLIENT_ID}/client-secret" -r application | jq -r .value)

#
# Kong
#
SERVICE_ID=$(curl -sS http://kong:8001/services/application-service | jq -r .id)
if [ "${SERVICE_ID}" = 'null' ]; then
    SERVICE_ID=$(curl -sS -X POST http://kong:8001/services -d name=application-service -d url=http://echo:8080/server/resources | jq -r .id)
    echo Created http://kong:8001/services/application-service
else
    curl -sS -X PATCH "http://kong:8001/services/${SERVICE_ID}" -d url=http://echo:8080/server/resources
    echo Updated http://kong:8001/services/application-service
fi

if [ -z "$(curl -sS http://kong:8001/routes/ | jq -r '.data[] | select(.name=="application-route")')" ]; then
    curl -sS -X POST http://kong:8001/routes -d name=application-route -d "service.id=${SERVICE_ID}" -d 'paths[]=/echo'
    echo Created http://kong:8001/routes/application-route
fi

plugin_id=$(curl -sS http://kong:8001/plugins/ | jq -r '.data[] | select(.name=="oidc") | .id')
if [ -z "$plugin_id" ]; then
    curl -sS -X POST http://kong:8001/plugins -d name=oidc -d config.client_id=kong \
        -d "config.client_secret=${SECRET}" \
        -d "config.discovery=http://${HOST_IP}:8180/auth/realms/application/.well-known/openid-configuration"
    echo Created oidc plugin
else
    curl -sS -X PATCH "http://kong:8001/plugins/${plugin_id}" \
        -d "config.discovery=http://${HOST_IP}:8180/auth/realms/application/.well-known/openid-configuration"
    echo Updated oidc plugin
fi

#
# Users
#
while read -r user_password; do
    user=${user_password%,*}

    user_id=$(kcadm.sh get users  -r application --fields username,id |  jq -r ".[] | select(.username==\"$user\") | .id")
    [ -z "${user_id}" ] && user_id=$(kcadm.sh create users --id -r application -s "username=${user}" -s enabled=true)
    kcadm.sh update "users/${user_id}/reset-password" -r application -s type=password -s "value=${user_password#*,}" -n
    echo "User $user created/updated"
done < /home/conf/users.txt

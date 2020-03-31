#!/bin/sh -eu

until curl -IsS http://kong:8001/status/ && curl -IsS http://keycloak:8080/; do
    echo
    sleep 1
done

if [ -z "${HOST_IP}" ]; then
    echo HOST_IP not defined, will skip setup
    exit 0
fi
echo "Setup for ${HOST_IP}"

#
# Keycloak
#
admin_token=$(curl -sS -X POST "http://keycloak:8080/auth/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" -H "Accept: application/json" \
    -d "username=${KEYCLOAK_USER}" -d "password=${KEYCLOAK_PASSWORD}" \
    -d 'grant_type=password' \
    -d 'client_id=admin-cli' | jq -r '.access_token')

if [ "404" = "$(curl -sS --head "http://keycloak:8080/auth/admin/realms/application" \
    -H "Authorization: Bearer ${admin_token}" -o /dev/null -w '%{http_code}')" ]; then
    curl -sS -w "\n" -X POST "http://keycloak:8080/auth/admin/realms" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d '{"realm": "application", "enabled": true}'
    echo Created realm application
fi

flow=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/authentication/flows" \
    -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" |
    jq -r '.[] | select(.alias == "Identity first browser")')
if [ -z "$flow" ]; then
    curl -sS -X POST "http://keycloak:8080/auth/admin/realms/application/authentication/flows" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d '{
                "alias": "Identity first browser", "description": "Two-steps browser based authentication",
                "providerId": "basic-flow", "topLevel": true, "builtIn": false
            }'
    flow=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/authentication/flows" \
        -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" |
        jq -r '.[] | select(.alias == "Identity first browser")')
    echo Created 'Identity first browser' flow
fi

if [ -z "$(echo "$flow" | jq -r '.authenticationExecutions[] | select(.authenticator=="auth-username-form")')" ]; then
    curl -sS -X POST "http://keycloak:8080/auth/admin/realms/application/authentication/executions" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d '{
                "authenticator":"auth-username-form", "requirement": "REQUIRED", "parentFlow":"'"$(echo "$flow" | jq -r .id)"'"
            }'
    echo Added username form to flow
fi

if [ -z "$(echo "$flow" | jq -r '.authenticationExecutions[] | select(.authenticator=="auth-password-form")')" ]; then
    curl -sS -X POST "http://keycloak:8080/auth/admin/realms/application/authentication/executions" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d '{
                "authenticator":"auth-password-form", "requirement": "REQUIRED", "parentFlow":"'"$(echo "$flow" | jq -r .id)"'"
            }'
    echo Added password form to flow
fi

curl -sS -X PUT "http://keycloak:8080/auth/admin/realms/application" \
    -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
    -d "$(
        curl -sS "http://keycloak:8080/auth/admin/realms/application" \
            -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" |
            jq '.browserFlow |= "Identity first browser"'
    )"
echo Configured 'Identity first browser' flow as the default flow

client=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/clients" \
    -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" | jq -r '.[] | select(.clientId=="kong")')
if [ -z "${client}" ]; then
    curl -sS -w "\n" -X POST "http://keycloak:8080/auth/admin/realms/application/clients" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d '{
            "clientId": "kong", "enabled": true, "publicClient": false,
            "redirectUris": ["http://'"${HOST_IP}"':8000/*"],
            "protocolMappers": [
                {
                "name": "tenant", "protocol": "openid-connect", "protocolMapper": "oidc-hardcoded-claim-mapper", "consentRequired": false,
                "config": {
                    "claim.name": "tenant", "jsonType.label": "String", "claim.value": "application",
                    "userinfo.token.claim": "true", "id.token.claim": "false", "access.token.claim": "false"
                    }
                }
            ]
        }'

    client_id=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/clients" \
        -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" |
        jq -r '.[] | select(.clientId=="kong") | .id')

    echo Created client kong in realm application
else
    client_id=$(echo "${client}" | jq -r .id)

    curl -sS -w "\n" -X PUT "http://keycloak:8080/auth/admin/realms/application/clients/${client_id}" \
        -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" -H "Accept: application/json" \
        -d "$(echo "${client}" | jq '.redirectUris |= [ "http://'"${HOST_IP}"':8000/*" ] | .webOrigins |= [ "http://'"${HOST_IP}"'" ]')"

    echo Updated client kong in realm application
fi
secret=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/clients/${client_id}/client-secret" \
    -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json" | jq -r .value)

#
# Kong
#
service_id=$(curl -sS http://kong:8001/services/application-service | jq -r .id)
if [ "${service_id}" = 'null' ]; then
    service_id=$(curl -sS -X POST http://kong:8001/services -d name=application-service -d url=http://echo:8080/server/ | jq -r .id)
    echo Created http://kong:8001/services/application-service
else
    curl -sS -w "\n" -X PATCH "http://kong:8001/services/${service_id}" -d url=http://echo:8080/server/
    echo Updated http://kong:8001/services/application-service
fi

route_id=$(curl -sS http://kong:8001/routes/ | jq -r '.data[] | select(.name=="application-route") | .id')
if [ -z "${route_id}" ]; then
    curl -sS -w "\n" -X POST http://kong:8001/routes -d name=application-route -d "service.id=${service_id}" -d 'paths[]=/echo' -d 'paths[]=/logout'
    echo Created http://kong:8001/routes/application-route
else
    curl -sS -w "\n" -X PATCH "http://kong:8001/routes/${route_id}" -d 'paths[]=/echo' -d 'paths[]=/logout'
    echo Updated http://kong:8001/routes/application-route
fi

plugin_id=$(curl -sS http://kong:8001/plugins/ | jq -r '.data[] | select(.name=="oidc") | .id')
if [ -z "${plugin_id}" ]; then
    curl -sS -w "\n" -X POST http://kong:8001/plugins -d name=oidc -d config.client_id=kong \
        -d "config.client_secret=${secret}" \
        -d "config.discovery=http://${HOST_IP}:8180/auth/realms/application/.well-known/openid-configuration" \
        -d "config.redirect_after_logout_uri=http://${HOST_IP}:8180/auth/realms/application/protocol/openid-connect/logout?redirect_uri=http%3A%2F%2F${HOST_IP}%3A8000%2Fecho%2F"

    echo Created oidc plugin
else
    curl -sS -w "\n" -X PATCH "http://kong:8001/plugins/${plugin_id}" \
        -d "config.discovery=http://${HOST_IP}:8180/auth/realms/application/.well-known/openid-configuration" \
        -d "config.redirect_after_logout_uri=http://${HOST_IP}:8180/auth/realms/application/protocol/openid-connect/logout?redirect_uri=http%3A%2F%2F${HOST_IP}%3A8000%2Fecho%2F"
    echo Updated oidc plugin
fi

#
# Users
#
users=$(curl -sS "http://keycloak:8080/auth/admin/realms/application/users" \
    -H "Authorization: Bearer ${admin_token}" -H "Accept: application/json")
while read -r user_password; do
    user=${user_password%,*}

    user_id=$(echo "${users}" | jq -r '.[] | select(.username=="'"${user}"'") | .id')
    if [ -z "${user_id}" ]; then
        curl -sS -w "\n" -X POST "http://keycloak:8080/auth/admin/realms/application/users" \
            -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" \
            -d '{
                "username": "'"${user}"'", "enabled": true,
                "credentials": [ {"type": "password", "value": "'"${user_password#*,}"'", "temporary": false} ]
                }'
        echo "User ${user} created"
    else
        curl -sS -w "\n" -X PUT "http://keycloak:8080/auth/admin/realms/application/users/${user_id}/reset-password" \
            -H "Authorization: Bearer ${admin_token}" -H "Content-Type: application/json" \
            -d '{"type": "password", "value": "'"${user_password#*,}"'", "temporary": false}'
        echo "User ${user} updated"
    fi
done </home/conf/users.txt

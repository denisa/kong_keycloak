# Kong - Keycloak - Konga
This project is a simple authenticating gateway build around [kong](https://konghq.com),
[keycloak](https://www.keycloak.org) and [konga](https://github.com/pantsel/konga).

Kong ensures every request is authenticated, keycloak is the IdP and kong provides a visualization for kong.
The [kong-oidc](https://github.com/nokia/kong-oidc) plugin handles the OIDC Relying Party (RP) functionality.

This project also shows automated setup and configuration of the components in a local docker-compose deployment.

A simplistic webapp shows all headers passed to the back end services.

The project is a playground to explore these technologies and does not represent best-practices, especially not related
to handling secrets in a docker deployment.

## Use
Launch with `./up`

The script ends with a link to the application (open it in a private browser window) and a list of all available users.

Shut the system down with `./down`

## Update the ip address when moving to a new network
Run the `./up` command again and it will update the settings as necessary.

# The webapp
Launch with
`docker run -p 8080:8080 -p 9990:9990 -it kong_keycloak`

`curl http://localhost:8080/server/resources/message`

```
curl http://localhost:8080/server/resources/message
No authorization header
```

```
curl -H 'Authorization: Basic foo' http://localhost:8080/server/resources/message
Not a Bearer  authorization
```

```
curl -H 'Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJKb2UifQ.Cy-XkzE1ZokAApN3c1S0ri0HSrdn8aKQi4HNRrbCgUE' http://localhost:8080/server/resources/message
```


# The docker-compose

Following assume that the mac IP is 192.168.42.72
1. Build the project with `mvn`
1. Launch with `docker-compose up -d`
1. `curl -s -X POST http://localhost:8001/services -d name=echo-service -d url=http://echo:8080/server/resources/message | jq .id`
returns the service_id to use on the next line
1. `curl -s -X POST http://localhost:8001/routes -d service.id=6906de36-1808-4e02-8170-643533652b51 -d 'paths[]=/echo'`
try with `curl http://localhost:8000/echo`
1. at `http://localhost:8180` (user _admin_, password _admin_)
    1. add a client:
        + click the "Clients" link in the sidebar, and then the "Create" button
        + fill in the "Client ID" as "kong", the Root URL as "http://192.168.42.72:8000", and click "Save"
        + set the "Access Type" to "Confidential", and click the "Save"
        + copy the secret from the "Credentials" page
    1. create user;
1. `curl -s -X POST http://localhost:8001/plugins -d name=oidc -d config.client_id=kong \
  -d config.client_secret=2eddf3f7-1b13-4520-9d9a-541110a3bc38 \
  -d config.discovery=http://192.168.42.72:8180/auth/realms/master/.well-known/openid-configuration \
  | jq .`
1. in safari, http://192.168.42.72:8000/echo

## Update the ip address when moving to a new network
1. `curl http://localhost:8001/plugins | jq '.data[] | select(.name=="oidc") | .id'` returns the oidc plugin id for use in 
1. `curl -s -X PATCH http://localhost:8001/plugins/46f801fb-3ac9-46a8-a3da-860b9743528d -d config.discovery=http://192.168.42.72:8180/auth/realms/master/.well-known/openid-configuration`
1. Update the Root URL in keycloak's kong client definition

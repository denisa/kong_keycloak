FROM kong:1.5.0-alpine
USER root
RUN sed -i '/rewrite_by_lua_block/i \\tset $session_secret nil;\n' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua
RUN apk add --no-cache git && \
    git clone https://github.com/nokia/kong-oidc.git /tmp/kong-oidc && \
    ( cd /tmp/kong-oidc && \
    sed -i 's/v[0-9]\+\.[0-9]\+\.[0-9]\+/master/g' kong-oidc-*.rockspec && \
    luarocks make )
USER kong

FROM kong:1.0.3-alpine

RUN sed -i '/rewrite_by_lua_block/i \\tset $session_secret nil;\n' /usr/local/share/lua/5.1/kong/templates/nginx_kong.lua
RUN luarocks install kong-oidc 1.1.0

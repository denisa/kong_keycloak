package com.weichaiamerica.svic.one_off.kong_keycloak;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jws;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;

import javax.ws.rs.GET;
import javax.ws.rs.HeaderParam;
import javax.ws.rs.Path;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import java.security.Key;
import java.util.Base64;

import static java.util.stream.Collectors.joining;

@Path("message")
public class MessageResource {
    //        Key key = Keys.secretKeyFor(SignatureAlgorithm.HS256);
    //        System.out.println(Base64.getEncoder().encodeToString(key.getEncoded()));
    static final Key KEY = Keys.hmacShaKeyFor(Base64.getDecoder().decode("YSZxW7WErpvNi1SJYp38sRxd39o/k7mz7JqcMJ0umbA="));
    private final String BEARER = "Bearer ";

    @GET
    public String all(@Context HttpHeaders headers) {
        return headers.getRequestHeaders().keySet().stream().sorted().collect(joining(", "));
    }

    @GET
    @Path("authorization")
    public String authorization(@HeaderParam("Authorization") final String authorization) {
        if (authorization == null) {
            return "No authorization header";
        }
        if (!authorization.startsWith(BEARER)) {
            return "Not a " + BEARER + " authorization";
        }
        try {
            final Jws<Claims> jws = Jwts.parser()
                    .setSigningKey(KEY)
                    .parseClaimsJws(authorization.substring(BEARER.length()));
            return "JWT token: " + jws;
        } catch (JwtException ex) {
            return "Exception parsing the token: " + ex;
        }
    }

    /**
     * payload from the Userinfo Endpoint
     */
    @GET
    @Path("userInfo")
    public String userInfo(@HeaderParam("X-Userinfo") final String userInfo) {
        return "UserInfo: " + new String(Base64.getDecoder().decode(userInfo));
    }

    @GET
    @Path("access")
    public String accessToken(@HeaderParam("X-Access-Token") final String accessToken) {
        return "access token: " + new String(Base64.getDecoder().decode(accessToken));
    }

    @GET
    @Path("id")
    public String idToken(@HeaderParam("X-Id-Token") final String idToken) {
        return "id: " + new String(Base64.getDecoder().decode(idToken));
    }
}

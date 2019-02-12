package com.weichaiamerica.svic.one_off.kong_keycloak;

import io.jsonwebtoken.Jwts;

public class JwtCreator {

    public static void main(String ... args){
        String jwt = Jwts.builder().setSubject("Joe").signWith(MessageResource.KEY).compact();
        System.out.println(jwt);}
}

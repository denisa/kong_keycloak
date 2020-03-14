package com.weichaiamerica.svic.one_off.kong_keycloak.echo;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import java.util.Base64;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

import static java.util.function.Function.identity;
import static java.util.stream.Collectors.toList;
import static java.util.stream.Collectors.toMap;

@Path("headers")
public class HeaderResource {
    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public Map<String, List<String>> all(@Context HttpHeaders headers) {
        return headers
                .getRequestHeaders()
                .entrySet()
                .stream()
                .collect(toMap(Map.Entry::getKey, s -> headerValues(headerToString(s.getKey()), s.getValue())));
    }

    private List<String> headerValues(final Function<String, String> headerToString, final List<String> headerValues) {
        return headerValues
                .stream()
                .sorted()
                .map(headerToString)
                .collect(toList());
    }

    private Function<String, String> headerToString(final String name) {
        switch (name) {
            case "X-Userinfo":
            case "X-ID-Token":
                return s -> new String(Base64.getDecoder().decode(s));
            default:
                return identity();
        }
    }
}

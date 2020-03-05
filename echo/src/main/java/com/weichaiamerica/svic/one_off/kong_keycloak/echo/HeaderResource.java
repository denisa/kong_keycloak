package com.weichaiamerica.svic.one_off.kong_keycloak.echo;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.Context;
import javax.ws.rs.core.HttpHeaders;
import javax.ws.rs.core.MediaType;
import java.util.Base64;
import java.util.List;
import java.util.function.Function;
import java.util.stream.Collectors;

import static java.util.function.Function.identity;
import static java.util.stream.Collectors.joining;

@Path("headers")
public class HeaderResource {
    @GET
    @Produces(MediaType.TEXT_HTML)
    public String all(@Context HttpHeaders headers) {
        return "<html><body><dl>" +
                headers
                        .getRequestHeaders()
                        .keySet()
                        .stream()
                        .sorted()
                        .map(s -> "<dt>" + s + "</dt>" +
                                headerValues(headerToString(s),
                                        headers
                                                .getRequestHeaders()
                                                .get(s)))
                        .collect(joining("\n")) +
                "</dl></body></html>";
    }

    private String headerValues(final Function<String, String> headerToString, final List<String> headerValues) {
        return headerValues
                .stream()
                .sorted()
                .map(v -> "<dd>" + headerToString.apply(v) + "</dd>")
                .collect(Collectors.joining("\n"));
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

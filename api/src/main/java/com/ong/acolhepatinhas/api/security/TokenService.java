package com.ong.acolhepatinhas.api.security;

import java.time.Instant;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import com.auth0.jwt.JWT;
import com.auth0.jwt.algorithms.Algorithm;
import com.auth0.jwt.exceptions.JWTCreationException;
import com.auth0.jwt.exceptions.JWTVerificationException;
import com.auth0.jwt.interfaces.DecodedJWT;
import com.ong.acolhepatinhas.api.user.User;

@Service
public class TokenService {

    @Value("${app.tokenIssuer}")
    private String ISSUER;
    
    @Value("${app.jwtTokenExpirationMs}")
    private Long EXPIRATION_TIME;
    
    @Value("${api.security.token.secret}")
    private String SECRET;

    public String generateToken(User user) {
        try {
            Algorithm signature = Algorithm.HMAC256(SECRET);

            return JWT.create()
                .withIssuer(ISSUER)
                .withSubject(user.getEmail())
                .withClaim("roles", user.getAuthorities().stream().map(auth -> auth.getAuthority()).toList())
                .withExpiresAt(Instant.now().plusMillis(EXPIRATION_TIME))
                .sign(signature);
        } catch (JWTCreationException e) {
            throw new RuntimeException("Erro ao gerar token: " + e.getMessage());
        }
    }

    public DecodedJWT validateToken(String token) {
        try {
            Algorithm signature = Algorithm.HMAC256(SECRET);

            return JWT.require(signature)
                .withIssuer(ISSUER)
                .build()
                .verify(token);
        } catch (JWTVerificationException e) {
            return null;
        }
    }
}

package com.ong.acolhepatinhas.api.security;

import java.io.IOException;
import java.util.Collections;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.auth0.jwt.interfaces.DecodedJWT;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class SecurityFilter extends OncePerRequestFilter {
    
    private final TokenService tknSvc;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {

        var token = getToken(request);

        if (token != null) {
            DecodedJWT decodedJwt = tknSvc.validateToken(token);

            if (decodedJwt != null) {
                String email = decodedJwt.getSubject();

                LoggedUserPayload user = new LoggedUserPayload(email);
                
                var authentication = new UsernamePasswordAuthenticationToken(user, null, Collections.emptyList()); 
                SecurityContextHolder.getContext().setAuthentication(authentication);
            }
        }

        filterChain.doFilter(request, response);
    }


    private String getToken(HttpServletRequest request) {
        var authHeader = request.getHeader("Authorization");
    
        if (authHeader != null) return authHeader.replace("Bearer ", "");
        else return null;
    }
}

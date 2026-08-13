package com.ong.acolhepatinhas.api.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;

import jakarta.validation.Valid;


@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authSvc;

    @PostMapping("/login")
    public ResponseEntity<TokenResponse> authenticateUser(@RequestBody @Valid LoginRequest data) {
        TokenResponse token = new TokenResponse(authSvc.authUser(data));
        
        return ResponseEntity.status(HttpStatus.OK).body(token);
    }
}
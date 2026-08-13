package com.ong.acolhepatinhas.api.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.auth.DTO.RegisterRequest;
import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.NewUserResponse;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

import jakarta.validation.Valid;


@RestController
@RequestMapping("/auth")
public class AuthController {

    @Autowired
    private AuthService authSvc;

    @Autowired
    private UserService usrSvc;


    @PostMapping("/login")
    public ResponseEntity<TokenResponse> authenticateUser(@RequestBody @Valid LoginRequest data) {
        TokenResponse token = new TokenResponse(authSvc.authUser(data));
        return ResponseEntity.status(HttpStatus.OK).body(token);
    }

    @PostMapping("/register")
    public ResponseEntity<NewUserResponse> registerUser(@RequestBody @Valid RegisterRequest data) {
        UserResponse userData = usrSvc.newUser(data);
        String token = authSvc.authUser(new LoginRequest(data.email(), data.password()));
        NewUserResponse response = new NewUserResponse(token, userData);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }
}
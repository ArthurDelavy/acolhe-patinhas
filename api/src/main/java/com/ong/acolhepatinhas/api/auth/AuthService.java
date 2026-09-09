package com.ong.acolhepatinhas.api.auth;

import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.auth.DTO.RefreshSessionRequest;
import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;
import com.ong.acolhepatinhas.api.refreshtoken.RefreshToken;
import com.ong.acolhepatinhas.api.refreshtoken.RefreshTokenService;
import com.ong.acolhepatinhas.api.security.TokenService;
import com.ong.acolhepatinhas.api.user.User;

import jakarta.validation.Valid;

@Service
@Validated
public class AuthService {
    
    @Autowired
    private AuthenticationManager authMgr;

    @Autowired
    private TokenService tknSvc;

    @Autowired
    private RefreshTokenService rftSvc;

    public TokenResponse issueTokens(User user) {
        String authToken = tknSvc.generateToken(user);
        UUID refreshToken = rftSvc.newToken(user);

        return new TokenResponse(authToken, refreshToken);
    }

    public TokenResponse authUser(@Valid LoginRequest data) {
        
        UsernamePasswordAuthenticationToken usrPswTkn = new UsernamePasswordAuthenticationToken(data.email(), data.password());

        Authentication auth = authMgr.authenticate(usrPswTkn);

        User user = (User) auth.getPrincipal();
        String authToken = tknSvc.generateToken(user);


        UUID refreshToken = rftSvc.newToken(user);


        return new TokenResponse(authToken, refreshToken);
    }


    @Transactional
    public TokenResponse refreshSession(@Valid RefreshSessionRequest data) {

        RefreshToken token = rftSvc.refreshToken(data);

        UUID refreshToken = token.getCode();
        String authToken = tknSvc.generateToken(token.getUser());

        return new TokenResponse(authToken, refreshToken);
        
    }
}

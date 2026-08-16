package com.ong.acolhepatinhas.api.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.stereotype.Service;

import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.security.TokenService;
import com.ong.acolhepatinhas.api.user.User;

@Service
public class AuthService {
    
    @Autowired
    private AuthenticationManager authMgr;

    @Autowired
    private TokenService tknSvc;

    public String authUser(LoginRequest data) {
        
        UsernamePasswordAuthenticationToken usrPswTkn = new UsernamePasswordAuthenticationToken(data.email(), data.password());

        Authentication auth = authMgr.authenticate(usrPswTkn);

        User user = (User) auth.getPrincipal();
        return tknSvc.generateToken(user);
    }
}

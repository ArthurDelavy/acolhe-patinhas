package com.ong.acolhepatinhas.api.utils;

import java.security.SecureRandom;

import org.springframework.beans.factory.annotation.Autowired;

import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCodeRepository;

public class PasswordCode {
    
    private static final String CHARS = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    private static final SecureRandom random = new SecureRandom();
    
    @Autowired
    PasswordChangeCodeRepository pswRep;

    public static String generateCode() {
        
        StringBuilder code = new StringBuilder(6);

        for (int i = 0; i < 6; i++) {
            int idx = random.nextInt(CHARS.length());
            code.append(CHARS.charAt(idx));
        }

        return code.toString();
    }
}

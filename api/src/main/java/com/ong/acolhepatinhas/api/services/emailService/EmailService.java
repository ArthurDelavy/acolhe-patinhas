package com.ong.acolhepatinhas.api.services.emailService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class EmailService {
    
    @Autowired
    private final EmailGateway emailGateway;

    public void resetPasswordEmail(String to, String token) {
        
        String subject = "ACOLHE PATINHAS | Redefinição de Senha";
        String body = "Seu código de confirmação para troca da senha da conta é: " + token;
        
        emailGateway.sendEmail(to, subject, body);
    }
}

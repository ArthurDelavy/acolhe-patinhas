package com.ong.acolhepatinhas.api.services.emailService;

import java.util.HashMap;
import java.util.Map;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import com.ong.acolhepatinhas.api.exceptions.custom.EmailSendingException;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class EmailService {
    
    @Autowired
    private final EmailGateway emailGateway;

    public void resetPasswordEmail(String name, String to, String token) {
        
        String subject = "ACOLHE PATINHAS | Redefinição de Senha";
        String template = "emails/reset-password";

        Map<String, Object> variables = new HashMap<>();
        variables.put("name", name);
        variables.put("token", token);
        
        try {
            emailGateway.sendEmail(to, subject, template, variables);
        } catch (EmailSendingException e) {
            
        }
    }


    public void newUserEmail(String name, String to) {

        String subject = "ACOLHE PATINHAS | Boas-Vindas";
        String template = "emails/welcome";

        Map<String, Object> variables = new HashMap<>();
        variables.put("name", name);
        
        try {
            emailGateway.sendEmail(to, subject, template, variables);
        } catch (EmailSendingException e) {
            
        }
    } 
}

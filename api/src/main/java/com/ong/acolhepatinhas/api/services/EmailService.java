package com.ong.acolhepatinhas.api.services;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {
    
    @Autowired
    JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String sender;

    public void resetPasswordEmail(String to, String token) {
        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(sender);
        message.setTo(to);
        message.setSubject("ACOLHE PATINHAS | Redefinição de Senha");
        message.setText("Seu código de confirmação para troca da senha da conta é: " + token);

        mailSender.send(message);
    }

    public void verificationEmail(String to, String code) {
        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(sender);
        message.setTo(to);
        message.setSubject("ACOLHE PATINHAS | Verificação de E-mail");
        message.setText("Seu código de verificação de e-mail é: " + code + "\n\nEste código expira em 24 horas. Se você não se cadastrou na Acolhe Patinhas, ignore esta mensagem.");

        mailSender.send(message);
    }
}

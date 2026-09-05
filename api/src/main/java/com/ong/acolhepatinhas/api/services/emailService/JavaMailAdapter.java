package com.ong.acolhepatinhas.api.services.emailService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Component;

import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class JavaMailAdapter implements EmailGateway {
    
    @Autowired
    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private final String sender;



    @Override
    public void sendEmail(String to, String subject, String body) {
        
        SimpleMailMessage message = new SimpleMailMessage();

        message.setFrom(sender);
        message.setTo(to);
        message.setSubject(subject);
        message.setText(body);

        mailSender.send(message);
        
    }
}

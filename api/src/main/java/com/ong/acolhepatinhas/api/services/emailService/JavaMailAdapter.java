package com.ong.acolhepatinhas.api.services.emailService;

import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.stereotype.Component;
import org.thymeleaf.context.Context;
import org.thymeleaf.spring6.SpringTemplateEngine;

import com.ong.acolhepatinhas.api.exceptions.custom.EmailSendingException;

import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;

@Component
@RequiredArgsConstructor
public class JavaMailAdapter implements EmailGateway {
    
    private final JavaMailSender mailSender;
    private final SpringTemplateEngine templateEngine;

    @Value("${spring.mail.username}")
    private String sender;



    @Override
    public void sendEmail(String to, String subject, String template, Map<String, Object> variables) {
        
        try {
            MimeMessage mimeMessage = mailSender.createMimeMessage();
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
    
            Context context = new Context();
            context.setVariables(variables);
            String htmlContent = templateEngine.process(template, context);
    
            helper.setFrom(sender);
            helper.setTo(to);
            helper.setSubject(subject);
            helper.setText(htmlContent, true);
    
            mailSender.send(mimeMessage);

        } catch (Exception e) {

            System.err.print("Falha na comunicação com o provedor de e-mail: " + to + " | " + subject + " | " + e.getMessage());
            throw new EmailSendingException("Erro ao enviar email para " + to);
        }
    }
}

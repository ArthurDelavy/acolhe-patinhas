package com.ong.acolhepatinhas.api.services.emailService;

public interface EmailGateway {
    void sendEmail(String to, String subject, String body);
}

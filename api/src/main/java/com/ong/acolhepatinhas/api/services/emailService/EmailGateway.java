package com.ong.acolhepatinhas.api.services.emailService;

import java.util.Map;

public interface EmailGateway {
    void sendEmail(String to, String subject, String template, Map<String, Object> variables);
}

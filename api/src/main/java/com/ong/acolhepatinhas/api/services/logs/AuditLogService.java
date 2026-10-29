package com.ong.acolhepatinhas.api.services.logs;

import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.services.logs.DTO.NewLogEventDTO;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;


@Service
@Slf4j
@Validated
@RequiredArgsConstructor 
public class AuditLogService {
    
    private final AuditLogRepository algRep;
    
    @Async
    @Transactional
    public void newLog(@Valid NewLogEventDTO data) {
        
        try {

            AuditLog log = AuditLog.builder()
            .actor(data.actor())
            .action(data.action())
            .resource(data.resource())
            .details(data.details())
            .ip(data.ip())
            .agent(data.agent())
            .timestamp(data.timestamp())
            .build();

            algRep.save(log);

        } catch (Exception e) {
            log.error("Erro ao salvar log de auditoria no banco: {}", data, e);
        }
    }

    
}

package com.ong.acolhepatinhas.api.services.logs;

import java.time.Instant;

import org.springframework.stereotype.Component;
import org.springframework.transaction.event.TransactionPhase;
import org.springframework.transaction.event.TransactionalEventListener;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.services.logs.DTO.NewLogEventDTO;
import com.ong.acolhepatinhas.api.utils.RequestInfo;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Component
@Validated
@RequiredArgsConstructor
public class AuditLogEventListener {
    
    private final AuditLogService logSvc;

    @TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT, fallbackExecution = true)
    public void saveUserActionLog(@Valid AuditLogEvent event) {
        
        logSvc.newLog(new NewLogEventDTO(
            event.actor(),
            event.action(),
            event.resource(),
            event.details(),    
            RequestInfo.getClientIp(),
            RequestInfo.getUserAgent(),
            Instant.now()
        ));

    }

}

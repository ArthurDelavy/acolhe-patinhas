package com.ong.acolhepatinhas.api.services.logs.DTO;

import jakarta.validation.constraints.NotBlank;

public record AuditLogEvent(

    @NotBlank
    String action,
    
    String resource,
    String details

) {
}

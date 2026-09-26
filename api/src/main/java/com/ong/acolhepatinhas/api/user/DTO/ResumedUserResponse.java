package com.ong.acolhepatinhas.api.user.DTO;

import java.time.OffsetDateTime;

import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.user.User;

import io.swagger.v3.oas.annotations.media.Schema;

public record ResumedUserResponse(

    @Schema(example = "1")
    Integer id,

    @Schema(example = "Fulano de Tal")
    String name,

    @Schema(example = "email@dominio.com")
    String email,

    @Schema(example = "USER")
    Role role,

    @Schema(example = "2026-08-16T18:18:35Z")
    OffsetDateTime createdAt
) {

    public ResumedUserResponse(User data) {
        this(
            data.getId(), 
            data.getName(), 
            data.getEmail(), 
            data.getRole(), 
            data.getCreatedAt()
        );
    }
}

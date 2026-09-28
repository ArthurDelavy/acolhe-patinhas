package com.ong.acolhepatinhas.api.user.DTO;

import java.time.OffsetDateTime;

import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.user.User;

import io.swagger.v3.oas.annotations.media.Schema;

public record UserResponse(

    @Schema(example = "1")
    Integer id,

    @Schema(example = "Fulano de Tal")
    String name,

    @Schema(example = "email@dominio.com")
    String email,

    @Schema(example = "USER")
    Role role,

    @Schema(example = "2026-08-16T18:18:35Z")
    OffsetDateTime createdAt,

    @Schema(example = "2027-08-16T18:18:35Z")
    OffsetDateTime deletedAt,

    @Schema(example = "true")
    boolean isEmailVerified
) {

    public static UserResponse from(User user) {
        if (user == null) return null;

        return new UserResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getRole(),
            user.getCreatedAt(),
            user.getDeletedAt(),
            user.isEmailVerified()
        );
    } 
}

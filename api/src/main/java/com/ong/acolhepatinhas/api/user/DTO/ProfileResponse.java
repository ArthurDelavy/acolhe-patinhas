package com.ong.acolhepatinhas.api.user.DTO;

import java.time.OffsetDateTime;

import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.user.User;

import io.swagger.v3.oas.annotations.media.Schema;

public record ProfileResponse(

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

    @Schema(example = "true")
    boolean isEmailVerified,

    @Schema(example = "https://storage.example/user/avatar/1_uuid.jpg")
    String profileImageUrl,

    @Schema (example = "Voluntário na Acolhe Patinhas")
    String description
) {

    public static ProfileResponse from(User user) {
        if (user == null) return null;

        return new ProfileResponse(
            user.getId(),
            user.getName(),
            user.getEmail(),
            user.getRole(),
            user.getCreatedAt(),
            user.isEmailVerified(),
            user.getProfileImageUrl(),
            user.getDescription()
        );
    }
}


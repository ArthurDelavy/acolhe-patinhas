package com.ong.acolhepatinhas.api.user.DTO;

import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;

import io.swagger.v3.oas.annotations.media.Schema;

public record NewUserResponse(

    @Schema(example = "Token de acesso e renovacao")
    TokenResponse tokens,

    @Schema(example = "Bearer")
    String tokenType,

    @Schema(description = "Dados do usuario")
    UserResponse user

) {

    public NewUserResponse(TokenResponse accessToken, UserResponse user) {
        this(accessToken, "Bearer", user);
    }
}

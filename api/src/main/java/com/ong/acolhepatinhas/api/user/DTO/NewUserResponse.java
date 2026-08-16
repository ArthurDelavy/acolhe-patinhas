package com.ong.acolhepatinhas.api.user.DTO;

import io.swagger.v3.oas.annotations.media.Schema;

public record NewUserResponse(

    @Schema(example = "Bearer Yhue38493...", description = "Token JWT")
    String accessToken,

    @Schema(example = "Bearer")
    String tokenType,

    @Schema(description = "Dados do usuario")
    UserResponse user

) {

    public NewUserResponse(String accessToken, UserResponse user) {
        this(accessToken, "Bearer", user);
    }
}

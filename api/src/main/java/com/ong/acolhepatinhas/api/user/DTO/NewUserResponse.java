package com.ong.acolhepatinhas.api.user.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record NewUserResponse(

    @NotBlank
    String accessToken,

    @NotNull
    UserResponse user

) {

    public NewUserResponse {
        if (accessToken != null && !accessToken.startsWith("Bearer ")) {
            accessToken = "Bearer " + accessToken;
        }
    }
}

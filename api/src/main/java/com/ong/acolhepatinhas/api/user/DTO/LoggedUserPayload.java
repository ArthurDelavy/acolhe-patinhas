package com.ong.acolhepatinhas.api.user.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;

public record LoggedUserPayload(

    @Email @NotBlank
    String email
) {
}

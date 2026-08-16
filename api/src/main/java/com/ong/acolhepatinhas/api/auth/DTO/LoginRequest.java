package com.ong.acolhepatinhas.api.auth.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record LoginRequest(

    @Email @NotBlank @Size(max = 150)
    String email,

    @NotBlank @Size(max = 100)
    String password
) {
}

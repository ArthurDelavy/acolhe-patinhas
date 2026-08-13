package com.ong.acolhepatinhas.api.auth.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

    @NotBlank @Size(min = 3, max = 50)
    String name,

    @Email @NotBlank @Size(max = 50)
    String email,

    @NotBlank @Size(max = 100)
    String password
) {
}

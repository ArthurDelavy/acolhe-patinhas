package com.ong.acolhepatinhas.api.auth.DTO;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record RegisterRequest(

    @NotBlank @Size(min = 3, max = 100)
    String name,

    @Email @NotBlank @Size(max = 150)
    String email,

    @NotBlank @Size(max = 100) @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$", message = "A senha não atende aos requisitos mínimos de complexidade (a-z, A-Z, 0-9, [@$!%*?&], >=8).")
    String password
) {
}

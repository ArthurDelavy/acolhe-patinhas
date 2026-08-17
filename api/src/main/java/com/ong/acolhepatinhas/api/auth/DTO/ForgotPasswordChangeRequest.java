package com.ong.acolhepatinhas.api.auth.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

public record ForgotPasswordChangeRequest(

    @Email @NotBlank @Size(max = 150)
    @Schema(example = "email@dominio.com.br")
    String email,

    @NotBlank @Size(min = 6, max = 6)
    @Schema(example = "3HGK5H")
    String passwordChangeToken,

    @NotBlank @Size(max = 100) @Pattern(regexp = "^(?=.*[a-z])(?=.*[A-Z])(?=.*\\d)(?=.*[@$!%*?&])[A-Za-z\\d@$!%*?&]{8,}$", message = "A senha não atende aos requisitos mínimos de complexidade (a-z, A-Z, 0-9, [@$!%*?&], >=8).")
    @Schema(example = "nova$3nha")
    String newPassword
) {
}

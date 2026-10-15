package com.ong.acolhepatinhas.api.user.DTO;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record ConfirmEmailChangeRequest(

    @NotBlank @Size(min = 6, max = 6)
    @Schema(example = "3HGK5H")
    String code
) {
}

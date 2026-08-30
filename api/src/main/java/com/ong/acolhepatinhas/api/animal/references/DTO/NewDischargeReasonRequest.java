package com.ong.acolhepatinhas.api.animal.references.DTO;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record NewDischargeReasonRequest(

    @NotBlank @Size(max = 20)
    String name
) {
}

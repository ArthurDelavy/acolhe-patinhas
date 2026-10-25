package com.ong.acolhepatinhas.api.fosterhome.DTO;

import com.ong.acolhepatinhas.api.fosterhome.FosterHome;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

public record NewFosterHomeRequest(

    @NotBlank @Email @Size(max = 150)
    @Schema(example = "email@dominio.com.br")
    String ownerEmail,

    @NotBlank @Size(min = 3, max = 50)
    @Schema(example = "Nome do Lar")
    String name,

    @NotBlank @Size(min = 11, max = 11) @Pattern(regexp = "^[1-9]{2}9[0-9]{8}$")
    @Schema(example = "51937294406")
    String phoneNumber,

    @NotBlank @Email @Size(max = 150)
    @Schema(example = "email@dominio.com.br")
    String email,

    @NotNull
    @DecimalMin(value = "-90.0")
    @DecimalMax(value = "90.0")
    @Digits(integer = 2, fraction = 8)
    @Schema(example = "-29.2361")
    Double latitude,

    @NotNull
    @DecimalMin(value = "-180.0")
    @DecimalMax(value = "180.0")
    @Digits(integer = 3, fraction = 8)
    @Schema(example = "-51.8697")
    Double longitude,

    @Positive
    @Schema(example = "15")
    int capacity
) { 

    public static NewFosterHomeRequest fromFosterHome(FosterHome data) {
        return new NewFosterHomeRequest(
            data.getOwner().getEmail(), 
            data.getName(), 
            data.getPhoneNumber(), 
            data.getEmail(), 
            data.getLocation().getY(), 
            data.getLocation().getX(), 
            data.getCapacity()
        );
    }
}

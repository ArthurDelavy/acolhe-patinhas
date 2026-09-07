package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO;

import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.Vaccine;

import io.swagger.v3.oas.annotations.media.Schema;

public record VaccineResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Polivalente")
    String name
) {

    public VaccineResponse(Vaccine data) {
        this(data.getId(), data.getName());
    }
}

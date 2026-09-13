package com.ong.acolhepatinhas.api.veterinary.medicine.DTO;

import com.ong.acolhepatinhas.api.veterinary.medicine.Medicine;

import io.swagger.v3.oas.annotations.media.Schema;

public record MedicineResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Maxicam")
    String name
) {

    public MedicineResponse(Medicine data) {
        this(data.getId(), data.getName());
    }
}

package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;

import io.swagger.v3.oas.annotations.media.Schema;

public record ColorResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Preto")
    String name
) {

    public ColorResponse(AnimalColor data) {
        this(data.getId(), data.getName());
    }
}

package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;

public record ColorResponse(

    int id,
    String name
) {

    public ColorResponse(AnimalColor data) {
        this(data.getId(), data.getName());
    }
}

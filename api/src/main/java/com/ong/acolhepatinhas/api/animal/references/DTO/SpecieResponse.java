package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

public record SpecieResponse(
    
    int id,
    String name
) {

    public SpecieResponse(AnimalSpecie data) {
        this(data.getId(), data.getName());
    }
}

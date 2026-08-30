package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

public record BreedResponse(

    int id,
    SpecieResponse specie,
    String name
    
) {

    public BreedResponse(AnimalBreed data) {
        this(data.getId(), new SpecieResponse(data.getSpecie()), data.getName());
    }
}

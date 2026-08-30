package com.ong.acolhepatinhas.api.animal.references.DTO;

import java.util.List;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

public record BreedResponse(

    List<AnimalBreed> breeds
    
) {
}

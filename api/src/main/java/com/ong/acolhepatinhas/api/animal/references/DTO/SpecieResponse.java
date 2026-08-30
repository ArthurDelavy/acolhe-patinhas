package com.ong.acolhepatinhas.api.animal.references.DTO;

import java.util.List;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

public record SpecieResponse(
    List<AnimalSpecie> species
) {
}

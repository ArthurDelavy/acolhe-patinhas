package com.ong.acolhepatinhas.api.animal.references.DTO;

import java.util.List;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;

public record ColorResponse(

    List<AnimalColor> colors
) {
}

package com.ong.acolhepatinhas.api.animal.references.DTO;

import java.util.List;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

public record ReferencesResponse(

    List<AnimalColor> colors,
    List<AnimalDischargeReason> dischargeReasons,
    List<AnimalSpecie> species
    
) {
}

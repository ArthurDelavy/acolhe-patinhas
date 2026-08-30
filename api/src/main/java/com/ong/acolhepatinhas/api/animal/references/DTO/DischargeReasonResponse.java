package com.ong.acolhepatinhas.api.animal.references.DTO;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;

public record DischargeReasonResponse(
   
    int id,
    String name
) {

    public DischargeReasonResponse(AnimalDischargeReason data) {
        this(data.getId(), data.getName());
    }
}

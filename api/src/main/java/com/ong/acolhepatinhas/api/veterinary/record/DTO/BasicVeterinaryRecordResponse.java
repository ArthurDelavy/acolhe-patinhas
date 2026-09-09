package com.ong.acolhepatinhas.api.veterinary.record.DTO;

import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;

import io.swagger.v3.oas.annotations.media.Schema;

public record BasicVeterinaryRecordResponse(

    @Schema(example = "1")
    int animalId,

    @Schema(example = "90", description = "Valor em cm")
    Integer size,

    
    @Schema(example = "1.5", description = "Valor em kg")
    Double weight,

    boolean neutered
) {

    public BasicVeterinaryRecordResponse(VeterinaryRecord data) {
        this(
            data.getId(), 
            data.getSize(), 
            data.getWeight(), 
            data.isNeutered()
        );
    }
    
}

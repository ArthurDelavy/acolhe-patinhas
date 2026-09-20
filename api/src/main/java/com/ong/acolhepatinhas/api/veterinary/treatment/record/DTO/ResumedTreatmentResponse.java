package com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO;

import com.ong.acolhepatinhas.api.veterinary.treatment.record.Treatment;

import io.swagger.v3.oas.annotations.media.Schema;

public record ResumedTreatmentResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "Dermatite")
    String diseaseName,

    @Schema(example = "FINISHED")
    String status
) {

    public ResumedTreatmentResponse(Treatment data) {
        this(
            data.getId(), 
            data.getVetRecord().getId(), 
            data.getVetRecord().getAnimal().getName(), 
            data.getDiagnosis().getDisease().getName(), 
            data.getStatus().name()
        );
    }
}

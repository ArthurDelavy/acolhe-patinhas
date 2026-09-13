package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.Diagnosis;

import io.swagger.v3.oas.annotations.media.Schema;

public record DiagnosisResponse(
    
    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "Dermatite")
    String diseaseName,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate diagnosedAt,

    @Schema(example = "HEALED")
    String status
) {

    public DiagnosisResponse(Diagnosis data) {
        this(
            data.getId(), 
            data.getVetRecord().getId(), 
            data.getVetRecord().getAnimal().getName(), 
            data.getDisease().getName(), 
            data.getDiagnosedAt(), 
            data.getStatus().name()
        );
    }
}

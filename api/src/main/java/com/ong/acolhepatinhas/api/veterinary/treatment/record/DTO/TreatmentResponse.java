package com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.treatment.record.Treatment;

import io.swagger.v3.oas.annotations.media.Schema;

public record TreatmentResponse(
    
    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "1")
    int diagnosisId,

    @Schema(example = "Dermatite")
    String diseaseName,

    @Schema(example = "2026-09-03")
    LocalDate startDate,

    @Schema(example = "2026-11-09")
    LocalDate endDate,

    @Schema(example = "FINISHED")
    String status,

    @Schema(example = "...")
    String observations

) {

    public TreatmentResponse(Treatment data) {
        this(
            data.getId(), 
            data.getVetRecord().getAnimal().getId(), 
            data.getVetRecord().getAnimal().getName(), 
            data.getDiagnosis().getId(), 
            data.getDiagnosis().getDisease().getName(), 
            data.getStartDate(), 
            data.getEndDate(), 
            data.getStatus().name(), 
            data.getObservations()
        );
    }
}

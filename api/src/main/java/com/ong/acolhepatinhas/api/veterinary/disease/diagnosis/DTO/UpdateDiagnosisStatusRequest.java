package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO;

import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.enums.DiseaseStatus;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotNull;

public record UpdateDiagnosisStatusRequest(
    
    @NotNull
    @Schema(example = "HEALED")
    DiseaseStatus status
){
    
}

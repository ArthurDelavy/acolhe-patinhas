package com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.labtest.result.LaboratoryTestResult;

import io.swagger.v3.oas.annotations.media.Schema;

public record ResumedLaboratoryTestResultResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "1")
    int labTestId,

    @Schema(example = "Hemograma")
    String labTestName,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate testDate
) {

    public ResumedLaboratoryTestResultResponse(LaboratoryTestResult data) {
        this(
            data.getId(),
            data.getVetRecord().getAnimal().getId(),
            data.getVetRecord().getAnimal().getName(),
            data.getLabTest().getId(),
            data.getLabTest().getName(),
            data.getTestDate()
        );
    }
}

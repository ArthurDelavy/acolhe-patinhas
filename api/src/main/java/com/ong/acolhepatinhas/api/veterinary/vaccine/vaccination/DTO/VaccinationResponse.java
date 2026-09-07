package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.Vaccination;

import io.swagger.v3.oas.annotations.media.Schema;

public record VaccinationResponse(

    @Schema(example = "1")
    int vaccinationId,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "Polivalente")
    String vaccineName,

    @Schema(example = "Única, reforço, anual, 1ª, 2ª, 3...")
    String dose,

    @Schema(example = "Laboratório xyz")
    String manufacturer,

    @Schema(example = "3746GHE92K3H8XV23")
    String batchNumer,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate vaccinationDate,

    @Schema(example = "2028-09-03T00:34:29.186Z")
    LocalDate nextDoseDate
) {

    public VaccinationResponse(Vaccination data) {
        this(
            data.getId(),
            data.getVetRecord().getId(),
            data.getVetRecord().getAnimal().getName(),
            data.getVaccine().getName(), 
            data.getDose(),
            data.getManufacturer(),
            data.getBatchNumber(),
            data.getVaccinationDate(), 
            data.getNextDoseDate()
        );
    }
}

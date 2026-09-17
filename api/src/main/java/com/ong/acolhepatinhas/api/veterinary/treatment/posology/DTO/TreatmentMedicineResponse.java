package com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.treatment.posology.TreatmentMedicine;

import io.swagger.v3.oas.annotations.media.Schema;

public record TreatmentMedicineResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int TreatmentId,

    @Schema(example = "1")
    int medicineId,

    @Schema(example = "Apoquel")
    String medicineName,

    @Schema(example = "1cp")
    String dosage,

    @Schema(example = "1x ao dia")
    String frequency,

    @Schema(example = "7")
    int durationDays,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate startDate
) {

    public TreatmentMedicineResponse(TreatmentMedicine data) {
        this(
            data.getId(), 
            data.getTreatment().getId(),
            data.getMedicine().getId(),
            data.getMedicine().getName(),
            data.getDosage(),
            data.getFrequency(), 
            data.getDurationDays(), 
            data.getStartDate()
        );
    }
}

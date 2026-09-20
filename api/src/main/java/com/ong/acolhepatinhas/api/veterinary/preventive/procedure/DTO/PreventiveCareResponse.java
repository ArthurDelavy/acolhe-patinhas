package com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.PreventiveCare;

import io.swagger.v3.oas.annotations.media.Schema;

public record PreventiveCareResponse(

    @Schema(example = "1")
    int preventiveCareId,

    @Schema(example = "1")
    int procedureId,

    @Schema(example = "Vermifugação")
    String procedureName,

    @Schema(example = "1")
    Integer medicineId,

    @Schema(example = "Maxicam")
    String medicineName,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    LocalDate procedureDate,

    @Schema(example = "2028-09-03T00:34:29.186Z")
    LocalDate nextProcedureDate,

    @Schema(example = "...")
    String observations
) {

    public PreventiveCareResponse(PreventiveCare data) {
        this(
            data.getId(), 
            data.getProcedure().getId(),
            data.getProcedure().getName(),
            data.getMedicine().getId(),
            data.getMedicine().getName(),
            data.getProcedureDate(),
            data.getNextProcedureDate(),
            data.getObservations()
        );
    }
}

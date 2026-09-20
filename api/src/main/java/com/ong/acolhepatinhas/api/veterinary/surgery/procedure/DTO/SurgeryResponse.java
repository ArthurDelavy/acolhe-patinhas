package com.ong.acolhepatinhas.api.veterinary.surgery.procedure.DTO;

import java.time.LocalDate;

import com.ong.acolhepatinhas.api.veterinary.surgery.procedure.Surgery;

import io.swagger.v3.oas.annotations.media.Schema;

public record SurgeryResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int animalId,

    @Schema(example = "Max")
    String animalName,

    @Schema(example = "1")
    int surgicalProcedureId,

    @Schema(example = "orquiectomia")
    String surgicalProcedureName,

    @Schema(example = "2028-09-03")
    LocalDate procedureDate,

    @Schema(example = "...")
    String observations

) {

    public SurgeryResponse(Surgery data) {
        this(
            data.getId(), 
            data.getVetRecord().getAnimal().getId(), 
            data.getVetRecord().getAnimal().getName(), 
            data.getSurgicalProcedure().getId(), 
            data.getSurgicalProcedure().getName(), 
            data.getProcedureDate(), 
            data.getObservations()
        );
    }
}

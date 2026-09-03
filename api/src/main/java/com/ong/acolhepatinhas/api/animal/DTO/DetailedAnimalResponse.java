package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.Instant;
import java.time.LocalDate;

import com.ong.acolhepatinhas.api.animal.Animal;

import io.swagger.v3.oas.annotations.media.Schema;

public record DetailedAnimalResponse(

    
    @Schema(example = "1")
    int id,
    
    @Schema(example = "Fulano")
    String user,
    
    @Schema(example = "Max")
    String name,
    
    @Schema(example = "274957392710462")
    String microchipNumber,

    @Schema(example = "Cachorro")
    String specie,
    
    @Schema(example = "1")
    String breed,
    
    @Schema(example = "1")
    String color,
    
    @Schema(example = "M")
    char gender,
    
    @Schema(example = "Cachorro")
    LocalDate birthDate,
    
    @Schema(example = "Cachorro")
    Instant intakeDate,
    
    @Schema(example = "2025-02-07T00:34:29.186Z")
    Instant dischargeDate,
    
    @Schema(example = "Óbito")
    String dischargeReason,
    
    @Schema(example = "false")
    boolean toAdoption,
    
    @Schema(example = "https://")
    String imageUrl

) {

    public DetailedAnimalResponse(Animal data) {
        this(
            data.getId(), 
            data.getUser().getName(),
            data.getName(), 
            data.getMicrochipNumber(), 
            data.getBreed().getSpecie().getName(), 
            data.getBreed().getName(), 
            data.getColor().getName(), 
            data.getGender().toString().charAt(0),
            data.getBirthDate(),
            data.getIntakeDate(),
            data.getDischargeDate(),
            data.getDischargeReason() != null ? data.getDischargeReason().getName() : null,
            data.isToAdoption(),
            data.getImageUrl()
        );
    }
}

package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.Instant;
import java.time.LocalDate;

import com.ong.acolhepatinhas.api.animal.Animal;

public record DetailedAnimalResponse(

    int id,
    String user,
    String name,
    String microchipNumber,
    String specie,
    String breed,
    String color,
    char gender,
    LocalDate birthDate,
    Instant intakeDate,
    Instant dischargeDate,
    String dischargeReason,
    boolean toAdoption

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
            data.isToAdoption()
        );
    }
}

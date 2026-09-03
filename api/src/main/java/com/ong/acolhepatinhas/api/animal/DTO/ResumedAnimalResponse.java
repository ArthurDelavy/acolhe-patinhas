package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.LocalDate;
import java.time.Period;

import com.ong.acolhepatinhas.api.animal.Animal;

public record ResumedAnimalResponse(

    int id,
    String name,
    String specie,
    String breed,
    String color,
    char gender,
    Integer age,
    boolean toAdoption,
    String imageUrl

) {
    
    public ResumedAnimalResponse(Animal data) {
        this(
            data.getId(), 
            data.getName(), 
            data.getBreed().getSpecie().getName(),
            data.getBreed().getName(), 
            data.getColor().getName(), 
            data.getGender().toString().charAt(0), 
            data.getBirthDate() != null ? Period.between(data.getBirthDate(), LocalDate.now()).getYears() : null,
            data.isToAdoption(),
            data.getImageUrl()
        );
    }
}

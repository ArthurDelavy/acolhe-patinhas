package com.ong.acolhepatinhas.api.animal.DTO;

import java.time.LocalDate;
import java.time.Period;

import com.ong.acolhepatinhas.api.animal.Animal;

import io.swagger.v3.oas.annotations.media.Schema;

public record ResumedAnimalResponse(

    @Schema(example = "id")
    int id,

    @Schema(example = "Max")
    String name,

    @Schema(example = "Cachorro")
    String specie,

    @Schema(example = "PitBull")
    String breed,

    @Schema(example = "Preto")
    String color,

    @Schema(example = "M")
    char gender,

    @Schema(example = "8")
    Integer age,

    @Schema(example = "false")
    boolean toAdoption,

    @Schema(example = "https://...")
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

package com.ong.acolhepatinhas.api.fosterhome.DTO;

import com.ong.acolhepatinhas.api.fosterhome.FosterHome;

import io.swagger.v3.oas.annotations.media.Schema;

public record ResumedFosterHomeResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Fulano de Tal")
    String ownerName,

    @Schema(example = "Nome do Lar")
    String name,

    @Schema(example = "15")
    int capacity

) {

    public ResumedFosterHomeResponse(FosterHome data) {
        this(
            data.getId(),
            data.getOwner().getName(),
            data.getName(), 
            data.getCapacity()  
        );
    }
}

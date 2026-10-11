package com.ong.acolhepatinhas.api.fosterhome.DTO;

import com.ong.acolhepatinhas.api.fosterhome.FosterHome;

import io.swagger.v3.oas.annotations.media.Schema;

public record FosterHomeResponse(

    @Schema(example = "Fulano de Tal")
    String userName,

    @Schema(example = "Fulano de Tal")
    String ownerName,

    @Schema(example = "Nome do Lar")
    String name,

    @Schema(example = "11940028922")
    String phoneNumber,

    @Schema(example = "email@dominio.com.br")
    String email,

    @Schema(example = "-29.2361")
    Double latitude,

    @Schema(example = "-51.8697")
    Double longitude,

    @Schema(example = "15")
    int capacity

) {

    public FosterHomeResponse(FosterHome data) {
        this(
            data.getUser().getName(),
            data.getOwner().getName(), 
            data.getName(), 
            data.getPhoneNumber(), 
            data.getEmail(), 
            data.getLocation().getY(),
            data.getLocation().getX(),
            data.getCapacity()  
        );
    }
}

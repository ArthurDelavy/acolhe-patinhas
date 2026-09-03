package com.ong.acolhepatinhas.api.services.DTO;

import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.constraints.NotNull;

public record ImageRequest(

    @NotNull
    MultipartFile image
) {
}

package com.ong.acolhepatinhas.api.services.imageService.DTO;

import org.springframework.web.multipart.MultipartFile;

import jakarta.validation.constraints.NotNull;

public record ImageRequest(

    @NotNull
    MultipartFile image
) {
}

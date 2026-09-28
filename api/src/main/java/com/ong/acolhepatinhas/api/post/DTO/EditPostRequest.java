package com.ong.acolhepatinhas.api.post.DTO;

import org.springframework.web.multipart.MultipartFile;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record EditPostRequest(

    MultipartFile image,

    @NotBlank @Size(max = 2200)
    @Schema(example = "Confira o resgate de hoje! 🐾")
    String description
) {
}
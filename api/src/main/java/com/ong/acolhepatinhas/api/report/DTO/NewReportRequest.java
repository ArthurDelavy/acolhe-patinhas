package com.ong.acolhepatinhas.api.report.DTO;

import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.report.enums.ReportType;

import io.swagger.v3.oas.annotations.media.Schema;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public record NewReportRequest(

    @NotNull
    @Schema(example = "LOST")
    ReportType type,
    
    @NotBlank @Size(min = 3, max = 120)
    @Schema(example = "Cachorro Perdido na Rua das Hortênsias")
    String title,

    @NotBlank @Size(min = 3, max = 5000)
    @Schema(example = "...")
    String description,

    MultipartFile image,

    @NotNull
    @DecimalMin(value = "-90.0")
    @DecimalMax(value = "90.0")
    @Digits(integer = 2, fraction = 8)
    @Schema(example = "-29.2361")
    Double latitude,

    @NotNull
    @DecimalMin(value = "-180.0")
    @DecimalMax(value = "180.0")
    @Digits(integer = 3, fraction = 8)
    @Schema(example = "-51.8697")
    Double longitude

) {
}

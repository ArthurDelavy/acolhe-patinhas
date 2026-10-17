package com.ong.acolhepatinhas.api.report.DTO;

import java.time.Instant;

import com.ong.acolhepatinhas.api.report.AnimalReport;

import io.swagger.v3.oas.annotations.media.Schema;

public record ReportResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "Fulano de Tal")
    String userName,
    
    @Schema(example = "LOST")
    String type,

    @Schema(example = "OPEN")
    String status,

    @Schema(example = "Cachorro Perdido na Rua das Hortênsias")
    String title,

    @Schema(example = "...")
    String description,

    @Schema(example = "https://")
    String imageUrl,
    
    @Schema(example = "-29.2361")
    Double latitude,

    @Schema(example = "-51.8697")
    Double longitude,

    @Schema(example = "2026-09-03")
    Instant createdAt,

    @Schema(example = "2026-09-03")
    Instant updatedAt
) {

    public ReportResponse(AnimalReport data) {
        this(
            data.getId(), 
            data.getUser().getName(), 
            data.getType().name(), 
            data.getStatus().name(), 
            data.getTitle(), 
            data.getDescription(), 
            data.getImageUrl(), 
            data.getLocation().getY(), 
            data.getLocation().getX(), 
            data.getCreatedAt(), 
            data.getUpdatedAt()
        );
    }
}

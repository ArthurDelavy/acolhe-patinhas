package com.ong.acolhepatinhas.api.post.DTO;

import java.time.OffsetDateTime;

import com.ong.acolhepatinhas.api.post.Post;

import io.swagger.v3.oas.annotations.media.Schema;

public record DetailedPostResponse(

    @Schema(example = "1")
    int id,

    @Schema(example = "1")
    int userId,

    @Schema(example = "Fulano")
    String userName,

    @Schema(example = "...")
    String description,

    @Schema(example = "https://...")
    String imageUrl,

    @Schema(example = "2026-09-03T00:34:29.186Z")
    OffsetDateTime createdAt

) {

    public DetailedPostResponse(Post data) {
        this(
            data.getId(),
            data.getUser().getId(),
            data.getUser().getName(),
            data.getDescription(),
            data.getImageUrl(),
            data.getCreatedAt()
        );
    }
}
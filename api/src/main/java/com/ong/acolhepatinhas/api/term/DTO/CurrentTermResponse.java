package com.ong.acolhepatinhas.api.term.DTO;

import io.swagger.v3.oas.annotations.media.Schema;

public record CurrentTermResponse(

    @Schema(example = "https://...")
    String url
) {
}

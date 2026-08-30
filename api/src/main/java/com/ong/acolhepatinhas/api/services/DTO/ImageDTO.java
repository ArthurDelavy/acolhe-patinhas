package com.ong.acolhepatinhas.api.services.DTO;

import org.springframework.web.multipart.MultipartFile;

public record ImageDTO(

    MultipartFile image
) {
}

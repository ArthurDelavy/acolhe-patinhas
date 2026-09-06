package com.ong.acolhepatinhas.api.services.imageService;

import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;

public interface ImageGateway {
    String uploadImage(byte[] imageBytes, String fileName, StorageFileType fileType, String contentType);
    void deleteImage(String fileName, StorageFileType fileType);
}

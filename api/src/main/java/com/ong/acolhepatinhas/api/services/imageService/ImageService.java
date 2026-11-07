package com.ong.acolhepatinhas.api.services.imageService;

import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.UUID;

import javax.imageio.ImageIO;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.exceptions.custom.ImageProcessingException;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import net.coobird.thumbnailator.Thumbnails;
import net.coobird.thumbnailator.geometry.Positions;

@Service
@Validated
@RequiredArgsConstructor
public class ImageService {
    
    @Autowired
    private final ImageGateway imageGateway;


    @Value("${app.images.maxSizeKb}")
    private int maxSizeImageKb;

    @Value("${app.images.qualityStartCompression}")
    private float qualityStartCompression;


    public String saveImage(@Valid ImageRequest file, String namePrefix, StorageFileType fileType) {
        
        MultipartFile image = file.image();
        if (image == null || image.isEmpty()) throw new IllegalArgumentException("Imagem inválida.");
        this.assertIsImage(image);
        
        namePrefix = (namePrefix != null && !namePrefix.isBlank()) ? namePrefix.trim().toLowerCase().replaceAll("[^a-z0-9-]", "") : "img";

        String fileName = namePrefix + "_" + UUID.randomUUID() + ".jpg";
        byte[] imageBytes = optimizeImage(image, fileType);

        return imageGateway.uploadImage(imageBytes, fileName, fileType, "image/jpeg");
    }


    public void deleteImage(String url, StorageFileType fileType) {

        if (url == null || url.isBlank()) return;

        try {
            String fileName = url.substring(url.lastIndexOf('/') + 1);
            imageGateway.deleteImage(fileName, fileType);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }




    private void assertIsImage(MultipartFile image) {
        try (InputStream input = image.getInputStream()) {
            BufferedImage decoded = ImageIO.read(input);
            if (decoded == null) throw new IllegalArgumentException("O arquivo enviado não é uma imagem.");
        } catch (IOException e) {
            throw new ImageProcessingException("Erro ao ler imagem.");
        }
    }


    private byte[] optimizeImage(MultipartFile image, StorageFileType fileType) {

        int maxEdge = switch (fileType) {
            case ANIMAL_REGISTER_PHOTO -> 80;
            case POST_PHOTO -> 1080;
            case USER_PROFILE_PHOTO -> 512;
            case REPORT_PHOTO -> 1080;
        };

        long maxSizeBytes = maxSizeImageKb * 1024;

        try {
            BufferedImage originalImage = ImageIO.read(image.getInputStream());

            if (originalImage == null) throw new ImageProcessingException("Imagem inválida");


            float quality = Math.min(qualityStartCompression, 0.85f);
            byte[] resultBytes;

            do {

                ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

                Thumbnails.of(originalImage)
                    .size(maxEdge, maxEdge)
                    .crop(Positions.CENTER)
                    .outputFormat("jpg")
                    .outputQuality(quality)
                    .toOutputStream(outputStream);

                resultBytes = outputStream.toByteArray();

                quality -= 0.10f;

            } while (resultBytes.length > maxSizeBytes && quality > 0.2f);

            return resultBytes;
        } catch (IOException e) {
            throw new ImageProcessingException("Falha ao otimizar imagem");
        }
    }
}

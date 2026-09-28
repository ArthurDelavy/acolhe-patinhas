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
import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.exceptions.custom.ImageProcessingException;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import net.coobird.thumbnailator.Thumbnails;

@Service
@RequiredArgsConstructor
public class ImageService {
    
    @Autowired
    private final ImageGateway imageGateway;


    @Value("${app.images.minCompressionKb}")
    private int minCompressionKb;

    @Value("${app.images.qualityCompression}")
    private float qualityCompression;


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
        
        if (image.getSize() < minCompressionKb * 1024) {
            try { return image.getBytes(); }
            catch (IOException e) { throw new ImageProcessingException("Erro ao ler imagem."); }
        }

        int maxEdge = switch (fileType) {
            case ANIMAL_REGISTER_PHOTO -> 80;
            case POST_PHOTO -> 1080;
        };

       try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            Thumbnails.of(image.getInputStream())
                .size(maxEdge, maxEdge)
                .outputFormat("jpg")
                .outputQuality(qualityCompression)
                .toOutputStream(outputStream);

            return outputStream.toByteArray();
        } catch (IOException e) { throw new ImageProcessingException("Falha ao otimizar imagem."); }
    }
}

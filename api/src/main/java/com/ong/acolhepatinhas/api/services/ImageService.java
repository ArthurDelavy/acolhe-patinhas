package com.ong.acolhepatinhas.api.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.services.DTO.ImageDTO;

import net.coobird.thumbnailator.Thumbnails;

@Service
public class ImageService {
    
    @Value("${app.images.datasource.url}")
    private String datasourceUrl;

    @Value("${app.images.datasource.key}")
    private String datasourceKey;

    @Value("${app.images.datasource.bucket}")
    private String datasourceBucket;


    @Value("${app.images.minCompressionKb}")
    private int minCompressionKb;

    @Value("${app.images.qualityCompression}")
    private float qualityCompression;

    private final RestClient restClient = RestClient.create();




    public String uploadImage(ImageDTO file) throws IOException {
        
        MultipartFile image = file.image();
        if (image == null || image.isEmpty()) throw new IllegalArgumentException("Imagem inválida.");
        
        String filename = UUID.randomUUID() + ".jpg";
        byte[] imageBytes = optimizeImage(image);
        String uploadUrl = String.format("%s/storage/v1/object/%s/%s", datasourceUrl, datasourceBucket, filename);

        restClient.post()
            .uri(uploadUrl)
            .header("Authorization", "Bearer " + datasourceKey)
            .header("Content-Type", "image/jpeg")
            .body(imageBytes)
            .retrieve()
            .toBodilessEntity();

        return String.format("%s/storage/v1/object/public/%s/%s", datasourceUrl, datasourceBucket, filename);
    }


    private byte[] optimizeImage(MultipartFile image) throws IOException {
        
        if (image.getSize() < minCompressionKb * 1024) return image.getBytes();

        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();

        Thumbnails.of(image.getInputStream())
            .size(80, 80)
            .outputFormat("jpg")
            .outputQuality(qualityCompression)
            .toOutputStream(outputStream);

        return outputStream.toByteArray();
    }
}

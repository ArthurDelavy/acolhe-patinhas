package com.ong.acolhepatinhas.api.services;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;
import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.exceptions.custom.ImageProcessingException;
import com.ong.acolhepatinhas.api.services.DTO.ImageRequest;

import jakarta.validation.Valid;
import net.coobird.thumbnailator.Thumbnails;

@Service
@Validated
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




    public String uploadImage(@Valid ImageRequest file) {
        
        MultipartFile image = file.image();
        if (image == null || image.isEmpty()) throw new IllegalArgumentException("Imagem inválida.");
        
        String filename = UUID.randomUUID() + ".jpg";
        byte[] imageBytes = optimizeImage(image);
        String uploadUrl = String.format("%s/storage/v1/object/%s/%s", datasourceUrl, datasourceBucket, filename);

        try {
            restClient.post()
                .uri(uploadUrl)
                .header("Authorization", "Bearer " + datasourceKey)
                .header("apikey", datasourceKey)
                .header("Content-Type", "image/jpeg")
                .body(imageBytes)
                .retrieve()
                .toBodilessEntity();
        } catch (RestClientException e) {
            System.err.print(e);
            throw new ImageProcessingException("Falha ao salvar imagem.");
        }

        return String.format("%s/storage/v1/object/public/%s/%s", datasourceUrl, datasourceBucket, filename);
    }


    private byte[] optimizeImage(MultipartFile image) {
        
        if (image.getSize() < minCompressionKb * 1024) {
            try { return image.getBytes(); }
            catch (IOException e) { throw new ImageProcessingException("Erro ao ler imagem."); }
        }

       try (ByteArrayOutputStream outputStream = new ByteArrayOutputStream()) {

            Thumbnails.of(image.getInputStream())
                .size(80, 80)
                .outputFormat("jpg")
                .outputQuality(qualityCompression)
                .toOutputStream(outputStream);

            return outputStream.toByteArray();
        } catch (IOException e) { throw new ImageProcessingException("Falha ao otimizar imagem."); }
    }
}

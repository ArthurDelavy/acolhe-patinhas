package com.ong.acolhepatinhas.api.services.imageService;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import com.ong.acolhepatinhas.api.exceptions.custom.StorageException;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;

@Component
public class SupabaseStorageAdapter implements ImageGateway {

    private final String datasourceUrl;
    private final String datasourceBucket;
    private final RestClient restClient;

    public SupabaseStorageAdapter(
        @Value("${app.images.datasource.url}") String datasourceUrl,
        @Value("${app.images.datasource.key}") String datasourceKey,
        @Value("${app.images.datasource.bucket}") String datasourceBucket
    ) {

        this.datasourceUrl = datasourceUrl;
        this.datasourceBucket = datasourceBucket;
        
        this.restClient = RestClient.builder()
                .baseUrl(datasourceUrl + "/storage/v1")
                .defaultHeader("Authorization", "Bearer " + datasourceKey)
                .defaultHeader("apikey", datasourceKey)
                .build();
    }






    @Override
    public String uploadImage(byte[] imageBytes, String fileName, StorageFileType fileType, String contentType) {

        if (imageBytes == null || imageBytes.length < 1 || fileName == null || fileName.isBlank()) throw new IllegalArgumentException("Imagem ou nome inválido.");
    
        String path = resolveFolder(fileType);
        String fullPath = "%s/%s".formatted(path, fileName);

        try {
            restClient.post()
                    .uri("/object/{bucket}/{filePath}", datasourceBucket, fullPath)
                    .header("Content-Type", contentType)
                    .body(imageBytes)
                    .retrieve()
                    .toBodilessEntity();
    
            return String.format("%s/storage/v1/object/public/%s/%s", datasourceUrl, datasourceBucket, fullPath);
            
        } catch (Exception e) {
            throw new StorageException("Erro ao salvar imagem em:" + fullPath, e);
        }
    }


    @Override
    public void deleteImage(String fileName, StorageFileType fileType) {

        if (fileName == null || fileName.isBlank()) throw new IllegalArgumentException("URL inválida.");

        String path = resolveFolder(fileType);
        String fullPath = "%s/%s".formatted(path, fileName);

        try {
            restClient.delete()
                .uri("/object/{bucket}/{filePath}", datasourceBucket, fullPath)
                .retrieve()
                .toBodilessEntity();

        } catch (Exception e) {
            throw new StorageException("Erro ao excluir imagem em: " + fullPath, e);
        }
    }




    private String resolveFolder(StorageFileType type) {
        return switch (type) {
            case ANIMAL_REGISTER_PHOTO -> "animal/avatar";
        };
    }
}

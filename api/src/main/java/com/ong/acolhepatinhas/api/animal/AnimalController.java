package com.ong.acolhepatinhas.api.animal;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.animal.DTO.ResumedAnimalResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal")
public class AnimalController {
    
    private final AnimalService anmSvc;

    @GetMapping @PreAuthorize("hasAuthority('animal:read')")
    @Operation(summary = "Lista todos os animais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedAnimalResponse>> listAll() {
        List<ResumedAnimalResponse> responseData = anmSvc.listAll()
            .stream()
            .map(ResumedAnimalResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }
}

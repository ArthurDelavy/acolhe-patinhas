package com.ong.acolhepatinhas.api.veterinary.record;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.record.DTO.BasicVeterinaryRecordResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/{animalId}/veterinary-record")
@Tag(name = "Dados Veterinários", description = "Dados variáveis dos animais")
public class VeterinaryRecordController {
    
    private final VeterinaryRecordService vtrSvc;

    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read', 'animal:read')")
    @Operation(summary = "Lista os dados veterinários básicos de um animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário não encontrado", content = @Content)
    public ResponseEntity<BasicVeterinaryRecordResponse> getBasicData(@PathVariable int animalId) {
        BasicVeterinaryRecordResponse responseData = new BasicVeterinaryRecordResponse(vtrSvc.getById(animalId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }
}
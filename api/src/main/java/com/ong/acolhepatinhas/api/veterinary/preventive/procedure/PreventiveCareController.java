package com.ong.acolhepatinhas.api.veterinary.preventive.procedure;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO.PreventiveCareResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/preventive")
@Tag(name = "Cuidados Preventivos", description = "Cadastro de cuidados preventivos")
public class PreventiveCareController {
    
    private final PreventiveCareService pvcSvc;

    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos os cuidados preventivos realizados")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<PreventiveCareResponse>> listAll() {
        List<PreventiveCareResponse> responseData = pvcSvc.listAll()
            .stream()
            .map(PreventiveCareResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{preventiveId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de uma preventiva específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Preventiva não encontrada", content = @Content)
    public ResponseEntity<PreventiveCareResponse> getById(@PathVariable int preventiveId) {
        PreventiveCareResponse responseData = new PreventiveCareResponse(pvcSvc.getById(preventiveId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping ("/{preventiveId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta uma preventiva específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Preventiva não encontrada", content = @Content)
    public ResponseEntity<Void> deletePreventive(@PathVariable int preventiveId) {
        pvcSvc.deletePreventive(preventiveId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

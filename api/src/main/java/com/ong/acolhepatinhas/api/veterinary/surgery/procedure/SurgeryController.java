package com.ong.acolhepatinhas.api.veterinary.surgery.procedure;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.surgery.procedure.DTO.SurgeryResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/surgery")
@Tag(name = "Cirurgias", description = "Cadastro de cirurgias")
public class SurgeryController {
    
    private final SurgeryService srgSvc;

    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas as cirurgias realizadas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<SurgeryResponse>> listAll() {
        List<SurgeryResponse> responseData = srgSvc.listAll()
            .stream()
            .map(SurgeryResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{surgeryId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de uma cirurgia específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Cirurgia não encontrada", content = @Content)
    public ResponseEntity<SurgeryResponse> getById(@PathVariable int surgeryId) {
        SurgeryResponse responseData = new SurgeryResponse(srgSvc.getById(surgeryId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping ("/{surgeryId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta uma cirurgia específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Cirurgia não encontrada", content = @Content)
    public ResponseEntity<Void> deleteSurgery(@PathVariable int surgeryId) {
        srgSvc.deleteSurgery(surgeryId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

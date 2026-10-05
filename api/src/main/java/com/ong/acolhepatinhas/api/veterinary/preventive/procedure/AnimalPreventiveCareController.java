package com.ong.acolhepatinhas.api.veterinary.preventive.procedure;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO.NewPreventiveCareRequest;
import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO.PreventiveCareResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/{animalId}/preventive")
@Tag(name = "Cuidados Preventivos", description = "Cadastro de cuidados preventivos")
public class AnimalPreventiveCareController {
    
    private final PreventiveCareService pvcSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas as preventivas do animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário não encontrado", content = @Content)
    public ResponseEntity<List<PreventiveCareResponse>> listByAnimal(@PathVariable int animalId) {
        List<PreventiveCareResponse> responseData = pvcSvc.listAllByAnimal(animalId)
            .stream()
            .map(PreventiveCareResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Cadastrar nova preventiva")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário, procedimento ou medicamento não encontrado", content = @Content)
    public ResponseEntity<PreventiveCareResponse> newPreventive(@PathVariable int animalId, @RequestBody @Valid NewPreventiveCareRequest data) {
        PreventiveCareResponse responseData = new PreventiveCareResponse(pvcSvc.newPreventive(animalId, data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }
}

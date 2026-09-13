package com.ong.acolhepatinhas.api.veterinary.disease.catalog;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO.DiseaseResponse;
import com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO.NewDiseaseRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/disease")
@Tag(name = "Doenças", description = "Cadastro de doenças")
public class DiseaseController {
    
    private final DiseaseService dseSvc;



    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista todas as doenças")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<DiseaseResponse>> listAll() {
        List<DiseaseResponse> responseData = dseSvc.listAll()
            .stream()
            .map(DiseaseResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @GetMapping("/{diseaseId}") @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista os dados de uma doença específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<DiseaseResponse> getById(@PathVariable int diseaseId) {
        DiseaseResponse responseData = new DiseaseResponse(dseSvc.getById(diseaseId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }



    @PostMapping @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Inserir nova doença")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Doença já cadastrada", content = @Content)
    public ResponseEntity<Void> newDisease(@RequestBody @Valid NewDiseaseRequest data) {
        dseSvc.newDisease(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }


    @DeleteMapping("/{diseaseId}") @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Excluir doença")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Doença não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Doença vinculada a um diagnóstico", content = @Content)
    public ResponseEntity<Void> deleteVaccine(@PathVariable int diseaseId) {
        dseSvc.deleteDisease(diseaseId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

package com.ong.acolhepatinhas.api.veterinary.preventive.catalog;

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

import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO.NewPreventiveProcedureRequest;
import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO.PreventiveProcedureResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/preventive/types")
@Tag(name = "Tipos de Procedimentos de Cuidados Preventivos", description = "Cadastro de tipos de procedimentos de cuidados preventivos")
public class PreventiveProcedureController {
    
    private final PreventiveProcedureService pvpSvc;


    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista todas os tipos de procedimentos")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<PreventiveProcedureResponse>> listAll() {
        List<PreventiveProcedureResponse> responseData = pvpSvc.listAll()
            .stream()
            .map(PreventiveProcedureResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @GetMapping("/{procedureId}") @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista os dados de um tipo de procedimento específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Procedimento não encontrado", content = @Content)
    public ResponseEntity<PreventiveProcedureResponse> getById(@PathVariable int procedureId) {
        PreventiveProcedureResponse responseData = new PreventiveProcedureResponse(pvpSvc.getById(procedureId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }



    @PostMapping @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Inserir novo tipo de procedimento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Tipo de procedimento já cadastrado", content = @Content)
    public ResponseEntity<PreventiveProcedureResponse> newProcedure(@RequestBody @Valid NewPreventiveProcedureRequest data) {
        PreventiveProcedureResponse responseData = new PreventiveProcedureResponse(pvpSvc.newProcedure(data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }


    @DeleteMapping("/{procedureId}") @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Excluir tipo de procedimento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Procedimento não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Tipo de procedimento vinculado a um cuidado preventivo", content = @Content)
    public ResponseEntity<Void> deleteProcedure(@PathVariable int procedureId) {
        pvpSvc.deleteProcedure(procedureId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

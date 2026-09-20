package com.ong.acolhepatinhas.api.veterinary.labtest.catalog;

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

import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.DTO.LaboratoryTestResponse;
import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.DTO.NewLaboratoryTestRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/lab-test/types")
@Tag(name = "Tipos de Testes Laboratoriais", description = "Cadastro de tipos de testes laboratoriais")
public class LaboratoryTestController {
    
    private final LaboratoryTestService lbtSvc;


    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista todos os tipos de testes laboratoriais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<LaboratoryTestResponse>> listAll() {
        List<LaboratoryTestResponse> responseData = lbtSvc.listAll()
            .stream()
            .map(LaboratoryTestResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @GetMapping("/{testId}") @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista os dados de um tipo de teste laboratorial específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Teste não encontrado", content = @Content)
    public ResponseEntity<LaboratoryTestResponse> getById(@PathVariable int testId) {
        LaboratoryTestResponse responseData = new LaboratoryTestResponse(lbtSvc.getById(testId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }



    @PostMapping @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Inserir novo tipo de teste laboratorial")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Tipo de teste laboratorial já cadastrado", content = @Content)
    public ResponseEntity<LaboratoryTestResponse> newTest(@RequestBody @Valid NewLaboratoryTestRequest data) {
        LaboratoryTestResponse responseData = new LaboratoryTestResponse(lbtSvc.newTest(data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }


    @DeleteMapping("/{testId}") @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Excluir tipo de teste laboratorial")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Teste não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Tipo de teste laboratorial vinculado a um resultado", content = @Content)
    public ResponseEntity<Void> deleteTest(@PathVariable int testId) {
        lbtSvc.deleteTest(testId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

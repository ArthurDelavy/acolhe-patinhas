package com.ong.acolhepatinhas.api.veterinary.labtest.result;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO.LaboratoryTestResultResponse;
import com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO.ResumedLaboratoryTestResultResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;


@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/lab-test")
@Tag(name = "Testes Laboratoriais", description = "Cadastro de testes laboratoriais")
public class LabTestResultController {
    
    private final LaboratoryTestResultService ltrSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos os testes laboratoriais realizados")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedLaboratoryTestResultResponse>> listAll() {
        List<ResumedLaboratoryTestResultResponse> responseData = ltrSvc.listAll()
            .stream()
            .map(ResumedLaboratoryTestResultResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{labTestResultId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de um teste laboratorial específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Teste laboratorial não encontrado", content = @Content)
    public ResponseEntity<LaboratoryTestResultResponse> getById(@PathVariable int labTestResultId) {
        LaboratoryTestResultResponse responseData = new LaboratoryTestResultResponse(ltrSvc.getById(labTestResultId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping ("/{labTestResultId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta um teste laboratorial específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Teste laboratorial não encontrado", content = @Content)
    public ResponseEntity<Void> deleteLabTest(@PathVariable int labTestResultId) {
        ltrSvc.deleteLabTest(labTestResultId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

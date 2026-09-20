package com.ong.acolhepatinhas.api.veterinary.labtest.result;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO.NewLaboratoryTestResultRequest;
import com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO.ResumedLaboratoryTestResultResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/{animalId}/lab-test")
@Tag(name = "Testes Laboratoriais", description = "Cadastro de testes laboratoriais")
public class AnimalLaboratoryTestResultController {
    
    private final LaboratoryTestResultService ltrSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas os testes laboratoriais do animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário não encontrado", content = @Content)
    public ResponseEntity<List<ResumedLaboratoryTestResultResponse>> listByAnimal(@RequestParam int animalId) {
        List<ResumedLaboratoryTestResultResponse> responseData = ltrSvc.listAllByAnimal(animalId)
            .stream()
            .map(ResumedLaboratoryTestResultResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Cadastrar novo teste laboratorial")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário ou tipo de teste laboratorial não encontrado", content = @Content)
    public ResponseEntity<Void> newLabTest(@RequestParam int animalId, @RequestBody @Valid NewLaboratoryTestResultRequest data) {
        ltrSvc.newLabTest(animalId, data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}

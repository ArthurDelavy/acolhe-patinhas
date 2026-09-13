package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO.DiagnosisResponse;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO.UpdateDiagnosisStatusRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/diagnosis")
@Tag(name = "Diagnósticos", description = "Cadastro de diagnósticos dos animais")
public class DiagnosisController {
    
    private final DiagnosisService dgnSvc;



    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos os diagnósticos")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<DiagnosisResponse>> listAll() {
        List<DiagnosisResponse> responseData = dgnSvc.listAll()
            .stream()
            .map(DiagnosisResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{diagnosisId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de um diagóstico específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Diagnóstico não encontrado", content = @Content)
    public ResponseEntity<DiagnosisResponse> getById(@PathVariable int diagnosisId) {
        DiagnosisResponse responseData = new DiagnosisResponse(dgnSvc.getById(diagnosisId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @PatchMapping("/{diagnosisId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Alterar status de diagnóstico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Alterado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Diagnóstico não encontrado", content = @Content)
    public ResponseEntity<Void> updateDiagnosisStatus(@PathVariable int diagnosisId, @Valid UpdateDiagnosisStatusRequest data) {
        dgnSvc.changeStatus(diagnosisId, data);
        return ResponseEntity.status(HttpStatus.OK).build();
    }


    @DeleteMapping ("/{diagnosisId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta um diagnóstico específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Diagnóstico não encontrado", content = @Content)
    public ResponseEntity<Void> deleteDiagnosis(@PathVariable int diagnosisId) {
        dgnSvc.deleteDiagnosis(diagnosisId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

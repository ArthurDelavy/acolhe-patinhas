package com.ong.acolhepatinhas.api.veterinary.treatment.record;

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

import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.EditTreatmentRequest;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.ResumedTreatmentResponse;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.TreatmentResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/treatment")
@Tag(name = "Tratamentos", description = "Cadastro de tratamentos dos animais")
public class TreatmentController {
    
    private final TreatmentService ttmSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos os tratamentos")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedTreatmentResponse>> listAll() {
        List<ResumedTreatmentResponse> responseData = ttmSvc.listAll()
            .stream()
            .map(ResumedTreatmentResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{treatmentId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de um tratamento específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Tratamento não encontrado", content = @Content)
    public ResponseEntity<TreatmentResponse> getById(@PathVariable int treatmentId) {
        TreatmentResponse responseData = new TreatmentResponse(ttmSvc.getById(treatmentId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @PatchMapping("/{treatmentId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Alterar dados de um tratamento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Alterado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Tratamento ou diagnóstico não encontrado", content = @Content)
    public ResponseEntity<Void> editTreatment(@PathVariable int treatmentId, @Valid EditTreatmentRequest data) {
        ttmSvc.editTreatment(treatmentId, data);
        return ResponseEntity.status(HttpStatus.OK).build();
    }


    @DeleteMapping ("/{treatmentId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta um tratamento específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Tratamento não encontrado", content = @Content)
    public ResponseEntity<Void> deleteTreatment(@PathVariable int treatmentId) {
        ttmSvc.deleteTreatment(treatmentId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

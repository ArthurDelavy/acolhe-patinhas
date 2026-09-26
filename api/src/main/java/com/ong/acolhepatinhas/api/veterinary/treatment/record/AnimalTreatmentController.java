package com.ong.acolhepatinhas.api.veterinary.treatment.record;

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

import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.NewTreatmentRequest;
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
@RequestMapping("/animal/{animalId}/treatment")
@Tag(name = "Tratamentos", description = "Cadastro de tratamentos dos animais")
public class AnimalTreatmentController {
    
    private final TreatmentService ttmSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos os tratamentos do animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário não encontrado", content = @Content)
    public ResponseEntity<List<ResumedTreatmentResponse>> listByAnimal(@PathVariable int animalId) {
        List<ResumedTreatmentResponse> responseData = ttmSvc.listAllByAnimal(animalId)
            .stream()
            .map(ResumedTreatmentResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Cadastrar novo tratamento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro ou diagnóstico não encontrado", content = @Content)
    public ResponseEntity<TreatmentResponse> newTreatment(@PathVariable int animalId, @RequestBody @Valid NewTreatmentRequest data) {
        TreatmentResponse responseData = new TreatmentResponse(ttmSvc.newTreatment(animalId, data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }
}


package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination;

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

import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO.NewVaccinationRequest;
import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO.ResumedVaccinationResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/{animalId}/vaccination")
@Tag(name = "Vacinação", description = "Cadastro de vacinações dos animais")
public class AnimalVaccinationController {
    
    private final VaccinationService vctSvc;

    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas as vacinas do animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro veterinário não encontrado", content = @Content)
    public ResponseEntity<List<ResumedVaccinationResponse>> listByAnimal(@RequestParam int animalId) {
        List<ResumedVaccinationResponse> responseData = vctSvc.listAllByAnimal(animalId)
            .stream()
            .map(ResumedVaccinationResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Cadastrar nova administração de vacina")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Registro ou vacina não encontrado", content = @Content)
    public ResponseEntity<Void> newVaccination(@RequestParam int animalId, @RequestBody @Valid NewVaccinationRequest data) {
        vctSvc.newVaccination(animalId, data);
        return ResponseEntity.status(HttpStatus.OK).build();
    }
}

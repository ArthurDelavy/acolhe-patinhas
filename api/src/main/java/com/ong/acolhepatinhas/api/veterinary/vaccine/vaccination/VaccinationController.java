package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO.ResumedVaccinationResponse;
import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO.VaccinationResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/vaccination")
@Tag(name = "Vacinação", description = "Cadastro de vacinações dos animais")
public class VaccinationController {

    private final VaccinationService vctSvc;

    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas as vacinas administradas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedVaccinationResponse>> listAll() {
        List<ResumedVaccinationResponse> responseData = vctSvc.listAll()
            .stream()
            .map(ResumedVaccinationResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{vaccinationId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de uma administração de vacina específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Vacinação não encontrada", content = @Content)
    public ResponseEntity<VaccinationResponse> getById(@PathVariable int vaccinationId) {
        VaccinationResponse responseData = new VaccinationResponse(vctSvc.getById(vaccinationId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping ("/{vaccinationId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta uma administração de vacina específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Vacinação não encontrada", content = @Content)
    public ResponseEntity<Void> deleteVaccination(@PathVariable int vaccinationId) {
        vctSvc.deleteVaccination(vaccinationId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

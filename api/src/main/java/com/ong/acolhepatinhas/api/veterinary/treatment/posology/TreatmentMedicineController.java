package com.ong.acolhepatinhas.api.veterinary.treatment.posology;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO.TreatmentMedicineResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/treatment/posology")
@Tag(name = "Tratamentos x Medicamentos", description = "Controle de administração de medicamentos durante tratamentos.")
public class TreatmentMedicineController {
    
    private final TreatmentMedicineService tmdSvc;



    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todos as administrações de medicamento em tratamentos")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<TreatmentMedicineResponse>> listAll() {
        List<TreatmentMedicineResponse> responseData = tmdSvc.listAll()
            .stream()
            .map(TreatmentMedicineResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{treatmentMedicineId}") @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista dados de uma administração de medicamento específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Administração de medicamento não encontrada", content = @Content)
    public ResponseEntity<TreatmentMedicineResponse> getById(@PathVariable int treatmentMedicineId) {
        TreatmentMedicineResponse responseData = new TreatmentMedicineResponse(tmdSvc.getById(treatmentMedicineId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping ("/{treatmentMedicineId}") @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Deleta uma administração de medicamento específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Administração não encontrada", content = @Content)
    public ResponseEntity<Void> deleteAdministration(@PathVariable int treatmentMedicineId) {
        tmdSvc.deleteAdministration(treatmentMedicineId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

package com.ong.acolhepatinhas.api.veterinary.treatment.posology;

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

import com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO.NewPosologyRequest;
import com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO.TreatmentMedicineResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/treatment/{treatmentId}/posology")
@Tag(name = "Tratamentos x Medicamentos", description = "Controle de administração de medicamentos durante tratamentos.")
public class TreatmentPosologyController {
    
    private final TreatmentMedicineService tmdSvc;


    @GetMapping @PreAuthorize("hasAuthority('veterinary:read')")
    @Operation(summary = "Lista todas as posologias do tratamento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Posologia não encontrada", content = @Content)
    public ResponseEntity<List<TreatmentMedicineResponse>> listByTreatment(@RequestParam int treatmentId) {
        List<TreatmentMedicineResponse> responseData = tmdSvc.listAllByTreatment(treatmentId)
            .stream()
            .map(TreatmentMedicineResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping @PreAuthorize("hasAuthority('veterinary:assign')")
    @Operation(summary = "Cadastrar nova posologia")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Tratamento ou medicamento não encontrado", content = @Content)
    public ResponseEntity<Void> newPosology(@RequestParam int treatmentId, @RequestBody @Valid NewPosologyRequest data) {
        tmdSvc.newPosology(treatmentId, data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }
}

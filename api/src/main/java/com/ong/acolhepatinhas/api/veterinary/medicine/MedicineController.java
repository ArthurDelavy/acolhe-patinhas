package com.ong.acolhepatinhas.api.veterinary.medicine;

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

import com.ong.acolhepatinhas.api.veterinary.medicine.DTO.MedicineResponse;
import com.ong.acolhepatinhas.api.veterinary.medicine.DTO.NewMedicineRequest;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/medicine")
@Tag(name = "Medicamentos", description = "Gerenciamento de medicamentos")
public class MedicineController {
    
    private final MedicineService mdcSvc;


    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista todos os medicamentos")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<MedicineResponse>> listAll() {
        List<MedicineResponse> responseData = mdcSvc.listAll()
            .stream()
            .map(MedicineResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @GetMapping("/{medicineId}") @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista os dados de um medicamento específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Medicamento não encontrado", content = @Content)
    public ResponseEntity<MedicineResponse> getById(@PathVariable int medicineId) {
        MedicineResponse responseData = new MedicineResponse(mdcSvc.getById(medicineId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }



    @PostMapping @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Inserir novo medicamento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Medicamento já cadastrado", content = @Content)
    public ResponseEntity<MedicineResponse> newMedicine(@RequestBody @Valid NewMedicineRequest data) {
        MedicineResponse responseData = new MedicineResponse(mdcSvc.newMedicine(data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }


    @DeleteMapping("/{medicineId}") @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Excluir medicamento")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Medicamento não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Medicamento vinculado a um tratamento ou cuidado preventivo", content = @Content)
    public ResponseEntity<Void> deleteMedicine(@PathVariable int medicineId) {
        mdcSvc.deleteMedicine(medicineId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

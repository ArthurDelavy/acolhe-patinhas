package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog;

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

import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO.NewVaccineRequest;
import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO.VaccineResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/veterinary/vaccine")
@Tag(name = "Vacinas", description = "Cadastro de vacinas")
public class VaccineController {
    
    private final VaccineService vccSvc;


    @GetMapping @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista todas as vacinas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<VaccineResponse>> listAll() {
        List<VaccineResponse> responseData = vccSvc.listAll()
            .stream()
            .map(VaccineResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{vaccineId}") @PreAuthorize("hasAnyAuthority('veterinary:read','veterinary:assign')")
    @Operation(summary = "Lista os dados de uma vacina específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Vacina não encontrada", content = @Content)
    public ResponseEntity<VaccineResponse> getById(@PathVariable int vaccineId) {
        VaccineResponse responseData = new VaccineResponse(vccSvc.getById(vaccineId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @PostMapping @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Inserir nova vacina")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Vacina já cadastrada", content = @Content)
    public ResponseEntity<Void> newVaccine(@RequestBody @Valid NewVaccineRequest data) {
        vccSvc.newVaccine(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }


    @DeleteMapping("/{vaccineId}") @PreAuthorize("hasAuthority('veterinary:manage')")
    @Operation(summary = "Excluir vacina")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Vacina não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Vacina vinculada a um animal", content = @Content)
    public ResponseEntity<Void> deleteVaccine(@PathVariable int vaccineId) {
        vccSvc.deleteVaccine(vaccineId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

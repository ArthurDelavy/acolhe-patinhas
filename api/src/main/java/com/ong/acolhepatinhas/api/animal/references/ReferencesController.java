package com.ong.acolhepatinhas.api.animal.references;

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

import com.ong.acolhepatinhas.api.animal.references.DTO.BreedResponse;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewBreedRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.ReferencesResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/reference")
public class ReferencesController {

    private final ReferencesService rfcSvc;

    @GetMapping @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Todos detalhes listáveis dos animais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<ReferencesResponse> listAll() {
       
        ReferencesResponse responseData = new ReferencesResponse(
            rfcSvc.listAllColors(),
            rfcSvc.listAllDischargeReasons(),
            rfcSvc.listAllSpeciesWithBreeds()
        );

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    // Raça
    @GetMapping("/breed") @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Lista de raças cadastradas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<BreedResponse> listAllBreeds() {
        BreedResponse responseData = new BreedResponse(rfcSvc.listAllBreeds());
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping("/breed") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Incluir nova raça")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Espécie referenciada não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Raça já cadastrada", content = @Content)
    public ResponseEntity<Void> newBreed(@RequestBody @Valid NewBreedRequest data) {
        rfcSvc.newBreed(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/breed/{id}") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Excluir raça")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Raça não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Raça vinculada a um animal", content = @Content)
    public ResponseEntity<Void> deleteBreed(@PathVariable int breedId) {
        rfcSvc.deleteBreed(breedId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }



}

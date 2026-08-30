package com.ong.acolhepatinhas.api.animal;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.animal.DTO.DetailedAnimalResponse;
import com.ong.acolhepatinhas.api.animal.DTO.EditAnimalRequest;
import com.ong.acolhepatinhas.api.animal.DTO.NewAnimalRequest;
import com.ong.acolhepatinhas.api.animal.DTO.ResumedAnimalResponse;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal")
public class AnimalController {
    
    private final AnimalService anmSvc;

    @GetMapping @PreAuthorize("hasAuthority('animal:read')")
    @Operation(summary = "Lista todos os animais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedAnimalResponse>> listAll() {
        List<ResumedAnimalResponse> responseData = anmSvc.listAll()
            .stream()
            .map(ResumedAnimalResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }



    @GetMapping("/{animalId}") @PreAuthorize("hasAuthority('animal:read')")
    @Operation(summary = "Lista todos os dados de um animal específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Animal não encontrado", content = @Content)
    public ResponseEntity<DetailedAnimalResponse> getById(@PathVariable int animalId) {
        DetailedAnimalResponse responseData = new DetailedAnimalResponse(anmSvc.getById(animalId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    

    @PostMapping @PreAuthorize("hasAuthority('animal:create')")
    @Operation(summary = "Inserir novo animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Animal/Microchip já cadastrado", content = @Content)
    public ResponseEntity<Void> newAnimal(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid NewAnimalRequest data) {
        anmSvc.newAnimal(user, data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }


    

    @PatchMapping("/{animalId}") @PreAuthorize("hasAuthority('animal:edit')")
    @Operation(summary = "Atualizar dados de um animal")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Atualizado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Animal/Microchip já cadastrado", content = @Content)
    public ResponseEntity<DetailedAnimalResponse> editAnimal(@AuthenticationPrincipal LoggedUserPayload user, @PathVariable int animalId, @RequestBody @Valid EditAnimalRequest data) {
        DetailedAnimalResponse responseData = new DetailedAnimalResponse(anmSvc.editAnimal(user, animalId, data));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }
}

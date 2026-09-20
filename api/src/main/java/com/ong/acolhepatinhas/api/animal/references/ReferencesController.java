package com.ong.acolhepatinhas.api.animal.references;

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

import com.ong.acolhepatinhas.api.animal.references.DTO.BreedResponse;
import com.ong.acolhepatinhas.api.animal.references.DTO.ColorResponse;
import com.ong.acolhepatinhas.api.animal.references.DTO.DischargeReasonResponse;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewBreedRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewColorRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewDischargeReasonRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewSpecieRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.ReferencesResponse;
import com.ong.acolhepatinhas.api.animal.references.DTO.SpecieResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/animal/reference")
@Tag(name = "Referências", description = "Gerenciamento de dados vinculados aos animais")
public class ReferencesController {

    private final ReferencesService rfcSvc;

    @GetMapping @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Todos detalhes listáveis dos animais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<ReferencesResponse> listAll() {
       
        List<ColorResponse> colors = rfcSvc.listAllColors().stream().map(ColorResponse::new).toList();
        List<DischargeReasonResponse> reasons = rfcSvc.listAllDischargeReasons().stream().map(DischargeReasonResponse::new).toList();
        List<SpecieResponse> species = rfcSvc.listAllSpecies().stream().map(SpecieResponse::new).toList();
        List<BreedResponse> breeds = rfcSvc.listAllBreeds().stream().map(BreedResponse::new).toList();

        ReferencesResponse responseData = new ReferencesResponse(colors, reasons, species, breeds);

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    // Raça
    @GetMapping("/breed") @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Lista de raças cadastradas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<BreedResponse>> listAllBreeds() {
        List<BreedResponse> responseData = rfcSvc.listAllBreeds()
            .stream()
            .map(BreedResponse::new)
            .toList();

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

    @DeleteMapping("/breed/{breedId}") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Excluir raça")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Raça não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Raça vinculada a um animal", content = @Content)
    public ResponseEntity<Void> deleteBreed(@PathVariable int breedId) {
        rfcSvc.deleteBreed(breedId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }



    // Especie
    
    @GetMapping("/specie") @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Lista de espécies cadastradas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<SpecieResponse>> listAllSpecies() {
        List<SpecieResponse> responseData = rfcSvc.listAllSpecies()
            .stream()
            .map(SpecieResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping("/specie") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Incluir nova espécie")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Espécie já cadastrada", content = @Content)
    public ResponseEntity<Void> newSpecie(@RequestBody @Valid NewSpecieRequest data) {
        rfcSvc.newSpecie(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/specie/{specieId}") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Excluir espécie")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Espécie não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Espécie vinculada a um animal", content = @Content)
    public ResponseEntity<Void> deleteSpecie(@PathVariable int specieId) {
        rfcSvc.deleteSpecie(specieId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }



    // Cor
    
    @GetMapping("/color") @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Lista de cores cadastradas")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ColorResponse>> listAllColors() {
        List<ColorResponse> responseData = rfcSvc.listAllColors()
            .stream()
            .map(ColorResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping("/color") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Incluir nova cor")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Cor já cadastrada", content = @Content)
    public ResponseEntity<Void> newColor(@RequestBody @Valid NewColorRequest data) {
        rfcSvc.newColor(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/color/{colorId}") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Excluir cor")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Cor não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Cor vinculada a um animal", content = @Content)
    public ResponseEntity<Void> deleteColor(@PathVariable int colorId) {
        rfcSvc.deleteColor(colorId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }



    // Motivo de Baixa
    
    @GetMapping("/dischargeReason") @PreAuthorize("hasAnyAuthority('animal:create', 'animal:edit', 'animalReference:manage')")
    @Operation(summary = "Lista de motivos de baixa cadastrados")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<DischargeReasonResponse>> listAllDischargeReasons() {
        List<DischargeReasonResponse> responseData = rfcSvc.listAllDischargeReasons()
            .stream()
            .map(DischargeReasonResponse::new)
            .toList();
            
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    @PostMapping("/discharge-reason") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Incluir novo motivo")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "409", description = "Motivo já cadastrado", content = @Content)
    public ResponseEntity<Void> newDischargeReason(@RequestBody @Valid NewDischargeReasonRequest data) {
        rfcSvc.newDischargeReason(data);
        return ResponseEntity.status(HttpStatus.CREATED).build();
    }

    @DeleteMapping("/discharge-reason/{reasonId}") @PreAuthorize("hasAuthority('animalReference:manage')")
    @Operation(summary = "Excluir motivo")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Excluído com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Motivo não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Motivo vinculado a um animal", content = @Content)
    public ResponseEntity<Void> deleteDischargeReason(@PathVariable int reasonId) {
        rfcSvc.deleteDischargeReason(reasonId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}
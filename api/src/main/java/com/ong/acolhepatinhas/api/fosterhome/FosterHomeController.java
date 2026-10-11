package com.ong.acolhepatinhas.api.fosterhome;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.fosterhome.DTO.FosterHomeResponse;
import com.ong.acolhepatinhas.api.fosterhome.DTO.NewFosterHomeRequest;
import com.ong.acolhepatinhas.api.fosterhome.DTO.ResumedFosterHomeResponse;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.parameters.RequestBody;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/foster-home")
@Tag(name = "Lares Temporários", description = "Gerenciamento de lares temporários")
public class FosterHomeController {
    
    private final FosterHomeService fhmSvc;


    @GetMapping @PreAuthorize("hasAuthority('fosterhome:read')")
    @Operation(summary = "Lista todos os lares temporários")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<List<ResumedFosterHomeResponse>> listAll() {
        List<ResumedFosterHomeResponse> responseData = fhmSvc.listAll()
            .stream()
            .map(ResumedFosterHomeResponse::new)
            .toList();

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("/{homeId}") @PreAuthorize("hasAuthority('fosterhome:read')")
    @Operation(summary = "Lista todos os dados de um lar temporário específico")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Lar não encontrado", content = @Content)
    public ResponseEntity<FosterHomeResponse> getById(@PathVariable int homeId) {
        FosterHomeResponse responseData = new FosterHomeResponse(fhmSvc.getById(homeId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @PostMapping @PreAuthorize("HasAuthority('fosterhome:create')")
    @Operation(summary = "Inserir novo lar temporário")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Lar já cadastrado", content = @Content)
    public ResponseEntity<ResumedFosterHomeResponse> newHome(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid NewFosterHomeRequest data) {
        ResumedFosterHomeResponse responseData = new ResumedFosterHomeResponse(fhmSvc.newHome(user, data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }


    @PatchMapping("/{homeId}") @PreAuthorize("hasAuthority('fosterhome:edit')")
    @Operation(summary = "Atualizar dados de um lar")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Atualizado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
        @ApiResponse(responseCode = "409", description = "Lar já cadastrado", content = @Content)
    public ResponseEntity<FosterHomeResponse> editHome(@AuthenticationPrincipal LoggedUserPayload user, @PathVariable int homeId, @RequestBody @Valid NewFosterHomeRequest data) {
        FosterHomeResponse responseData = new FosterHomeResponse(fhmSvc.editHome(user, homeId, data));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @DeleteMapping("/{homeId}") @PreAuthorize("hasAuthority('fosterhome:remove')")
    @Operation(summary = "Excluir um registro de lar")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Deletado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
    public ResponseEntity<Void> deleteAnimal(@PathVariable int homeId) {
        fhmSvc.deleteHome(homeId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

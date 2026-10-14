package com.ong.acolhepatinhas.api.term;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.term.DTO.CurrentTermResponse;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/term")
@Tag(name = "Termos", description = "Termos de Uso e Privacidade")
public class TermController {
    
    private final TermService trmSvc;

    @GetMapping
    @Operation(summary = "Obtém o link de acesso aos termos atualizados")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "500", description = "Nenhum termo encontrado")
    public ResponseEntity<CurrentTermResponse> getTerm() {
        CurrentTermResponse responseData = new CurrentTermResponse(trmSvc.getCurrentTermURL());

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @PostMapping("/accept") @PreAuthorize("hasAuthority('ROLE_TERMS_PENDING')")
    @Operation(summary = "Aceitar novo termo corrente", description = "Necessário novo login")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Termo aceito com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
    public ResponseEntity<Void> acceptTerm(@AuthenticationPrincipal LoggedUserPayload requester, HttpServletRequest request) {
        String clientIp = request.getRemoteAddr();

        trmSvc.acceptCurrentTerms(requester, clientIp);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}

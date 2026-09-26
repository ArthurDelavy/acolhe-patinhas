package com.ong.acolhepatinhas.api.user;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/user")
@Tag(name = "Usuários", description = "Gerenciamento de contas de usuários")
public class UserController {
    
    private final UserService usrSvc;


    @PatchMapping("/{userId}/toggle-verified") @PreAuthorize("hasAuthority('user:verify')")
    @Operation(summary = "Verificação de usuário")
        @ApiResponse(responseCode = "200", description = "Verificação alterada com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Usuários ADMIN não podem ser verificados", content = @Content)
    public ResponseEntity<Void> toggleVerified(@PathVariable int userId) {
        usrSvc.toggleUserVerification(userId);
        return ResponseEntity.status(HttpStatus.OK).build();
    }
}

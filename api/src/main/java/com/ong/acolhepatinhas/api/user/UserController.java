package com.ong.acolhepatinhas.api.user;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.user.DTO.ResumedUserResponse;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

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


    @GetMapping @PreAuthorize("hasAuthority('user:read')")
    @Operation(summary = "Lista todos os usuários")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
    public ResponseEntity<List<ResumedUserResponse>> listAll() {
        List<ResumedUserResponse> responseData = usrSvc.listAll()
            .stream()
            .map(ResumedUserResponse::new)
            .toList();
            
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


    @GetMapping("{/userId}") @PreAuthorize("hasAuthority('user:read')")
    @Operation(summary = "Lista os dados de um usuário específico")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
    public ResponseEntity<UserResponse> getById(@PathVariable int userId) {
        UserResponse responseData = UserResponse.from(usrSvc.getById(userId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }


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

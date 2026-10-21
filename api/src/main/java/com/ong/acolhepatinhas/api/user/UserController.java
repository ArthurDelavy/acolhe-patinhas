package com.ong.acolhepatinhas.api.user;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.auth.AuthService;
import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.auth.DTO.PasswordChangeRequest;
import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.user.DTO.ChangeEmailRequest;
import com.ong.acolhepatinhas.api.user.DTO.ConfirmEmailChangeRequest;
import com.ong.acolhepatinhas.api.user.DTO.EditDescriptionRequest;
import com.ong.acolhepatinhas.api.user.DTO.EditNameRequest;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.user.DTO.ProfileResponse;
import com.ong.acolhepatinhas.api.user.DTO.ResumedUserResponse;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/user")
@Tag(name = "Usuários", description = "Gerenciamento de contas de usuários")
public class UserController {
    
    private final UserService usrSvc;

    private final AuthService authSvc;


    @GetMapping("/me")
    @Operation(summary = "Dados do usuário autenticado")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
    public ResponseEntity<ProfileResponse> getProfile(@AuthenticationPrincipal LoggedUserPayload user) {
        return ResponseEntity.status(HttpStatus.OK).body(usrSvc.getProfile(user));
    }


    @PatchMapping("/me/name")
    @Operation(summary = "Alteração de nome do usuário autenticado")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Nome alterado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
    public ResponseEntity<ProfileResponse> changeName(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid EditNameRequest data) {
        return ResponseEntity.status(HttpStatus.OK).body(usrSvc.changeName(user, data));
    }

    @PatchMapping("/me/description")
    @Operation(summary = "Alteração da descrição do usuário autenticado")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Descrição alterada com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
    public ResponseEntity<ProfileResponse> changeDescription(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid EditDescriptionRequest data) {
        return ResponseEntity.status(HttpStatus.OK).body(usrSvc.changeDescription(user, data));
    }


    @PostMapping("/me/email")
    @Operation(summary = "Solicitação de código para troca de e-mail")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Código enviado para o novo e-mail!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "E-mail já cadastrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "E-mail atual não verificado, igual ao novo, ou acesso anônimo", content = @Content)
    public ResponseEntity<Void> requestEmailChange(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid ChangeEmailRequest data) {
        usrSvc.requestEmailChange(user, data);
        return ResponseEntity.ok().build();
    }


    @PostMapping("/me/email/confirm")
    @Operation(summary = "Confirmação da troca de e-mail")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "E-mail alterado com sucesso! Retorna os tokens da nova sessão.")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Código expirado ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário ou código não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "E-mail já cadastrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
    public ResponseEntity<TokenResponse> confirmEmailChange(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid ConfirmEmailChangeRequest data) {
        User account = usrSvc.confirmEmailChange(user, data);
        return ResponseEntity.status(HttpStatus.OK).body(authSvc.issueTokens(account));
    }


    @PatchMapping("/me/password")
    @Operation(summary = "Alteração de senha do usuário autenticado")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Senha alterada com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Senha incorreta", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Senha igual à antiga", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
    public ResponseEntity<TokenResponse> changePassword(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid PasswordChangeRequest data) {
        usrSvc.changePassword(user, data);
        TokenResponse tokens = authSvc.authUser(new LoginRequest(user.email(), data.newPassword()));
        return ResponseEntity.status(HttpStatus.OK).body(tokens);
    }


    @PatchMapping(value = "/me/photo", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @Operation(summary = "Alteração da foto de perfil")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Foto alterada com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Acessos anônimos não possuem perfil", content = @Content)
        @ApiResponse(responseCode = "500", description = "Erro ao salvar imagem", content = @Content)
    public ResponseEntity<ProfileResponse> setProfileImage(@AuthenticationPrincipal LoggedUserPayload user, @ModelAttribute ImageRequest image) {
        return ResponseEntity.status(HttpStatus.OK).body(usrSvc.setProfileImage(user, image));
    }


    @GetMapping @PreAuthorize("hasAuthority('user:read')")
    @Operation(summary = "Lista todos os usuários")
        @SecurityRequirement(name = "BearerToken")
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


    @GetMapping("/{userId}") @PreAuthorize("hasAuthority('user:read')")
    @Operation(summary = "Lista os dados de um usuário específico")
        @SecurityRequirement(name = "BearerToken")
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
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Verificação alterada com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "422", description = "Usuários ADMIN e Anônimos não podem ser verificados", content = @Content)
    public ResponseEntity<Void> toggleVerified(@PathVariable int userId) {
        usrSvc.toggleUserVerification(userId);
        return ResponseEntity.status(HttpStatus.OK).build();
    }
}


package com.ong.acolhepatinhas.api.auth;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.auth.DTO.LoginRequest;
import com.ong.acolhepatinhas.api.auth.DTO.PasswordChangeRequest;
import com.ong.acolhepatinhas.api.auth.DTO.RegisterRequest;
import com.ong.acolhepatinhas.api.auth.DTO.TokenResponse;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.user.DTO.NewUserResponse;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;


@RestController
@RequestMapping("/auth")
@Tag(name = "Usuários", description = "Gerenciamento de contas de usuários")
public class AuthController {

    @Autowired
    private AuthService authSvc;

    @Autowired
    private UserService usrSvc;


    @PostMapping("/login")
    @Operation(summary = "Login de usuário")
        @ApiResponse(responseCode = "200", description = "Usuário autenticado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Usuário e/ou senha incorretos", content = @Content)
    public ResponseEntity<TokenResponse> authenticateUser(@RequestBody @Valid LoginRequest data) {
        TokenResponse token = new TokenResponse(authSvc.authUser(data));
        return ResponseEntity.status(HttpStatus.OK).body(token);
    }

    @PostMapping("/register")
    @Operation(summary = "Cadastro de usuário")
        @ApiResponse(responseCode = "200", description = "Usuário criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "409", description = "E-mail já cadastrado", content = @Content)
    public ResponseEntity<NewUserResponse> registerUser(@RequestBody @Valid RegisterRequest data) {
        UserResponse userData = usrSvc.newUser(data);
        String token = authSvc.authUser(new LoginRequest(data.email(), data.password()));
        NewUserResponse response = new NewUserResponse(token, userData);

        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    
    @PatchMapping("/change-password")
    @Operation(summary = "Alteração de senha (usuário logado)")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Senha alterada com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Senha incorreta", content = @Content)
        @ApiResponse(responseCode = "404", description = "Usuário não encontrado", content = @Content)
        @ApiResponse(responseCode = "409", description = "Senha igual à antiga", content = @Content)        
    public ResponseEntity<TokenResponse> changePassword(@AuthenticationPrincipal LoggedUserPayload user, @RequestBody @Valid PasswordChangeRequest data) {
        usrSvc.changePassword(user, data);
        TokenResponse token = new TokenResponse(authSvc.authUser(new LoginRequest(user.email(), data.newPassword())));
        return ResponseEntity.status(HttpStatus.OK).body(token);
    }
    
}
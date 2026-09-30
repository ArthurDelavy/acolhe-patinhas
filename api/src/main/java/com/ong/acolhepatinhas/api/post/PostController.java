package com.ong.acolhepatinhas.api.post;

import java.nio.file.AccessDeniedException;

import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.post.DTO.DetailedPostResponse;
import com.ong.acolhepatinhas.api.post.DTO.EditPostRequest;
import com.ong.acolhepatinhas.api.post.DTO.NewPostRequest;
import com.ong.acolhepatinhas.api.post.DTO.PostPageResponse;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/post")
@Tag(name = "Postagens", description = "Feed de postagens dos usuários")
public class PostController {

    private final PostService pstSvc;

    // Listagem de postagens com paginação e ordenação
    @GetMapping @PreAuthorize("hasAuthority('post:read')")
    @Operation(summary = "Lista as postagens paginadas, ordenadas pela data")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Ordenação, página ou tamanho inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
    public ResponseEntity<PostPageResponse> listAll(
        @Parameter(description = "Ordenação pela data da postagem. asc = mais antigas primeiro, desc = mais recentes primeiro.", schema = @Schema(allowableValues = {"asc", "desc"}, defaultValue = "desc"))
        @RequestParam(required = false, defaultValue = "desc") String order,
        @Parameter(description = "Página, começando em 0.", schema = @Schema(defaultValue = "0"))
        @RequestParam(required = false, defaultValue = "0") int page,
        @Parameter(description = "Quantidade de itens por página, de 1 a 50.", schema = @Schema(defaultValue = "20"))
        @RequestParam(required = false, defaultValue = "20") int size
    ) {
        PostPageResponse responseData = new PostPageResponse(pstSvc.listAll(order, page, size));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    // Listagem de postagem específica
    @GetMapping("/{postId}") @PreAuthorize("hasAuthority('post:read')")
    @Operation(summary = "Lista os dados de uma postagem específica")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para acessar o conteúdo", content = @Content)
        @ApiResponse(responseCode = "404", description = "Postagem não encontrada", content = @Content)
    public ResponseEntity<DetailedPostResponse> getById(@PathVariable int postId) {
        DetailedPostResponse responseData = new DetailedPostResponse(pstSvc.getById(postId));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    // Criação de nova postagem
    @PostMapping(consumes = MediaType.MULTIPART_FORM_DATA_VALUE) @PreAuthorize("hasAuthority('post:create')")
    @Operation(summary = "Criar nova postagem")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "500", description = "Erro ao salvar imagem", content = @Content)
    public ResponseEntity<DetailedPostResponse> newPost(@AuthenticationPrincipal LoggedUserPayload user, @ModelAttribute @Valid NewPostRequest data) {
        DetailedPostResponse responseData = new DetailedPostResponse(pstSvc.newPost(user, data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }

    // Edição de postagem existente
    @PatchMapping(value = "/{postId}", consumes = MediaType.MULTIPART_FORM_DATA_VALUE) @PreAuthorize("hasAuthority('post:edit')")
    @Operation(summary = "Atualizar descrição e, se enviada, a imagem de uma postagem")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Atualizado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação, ou não é o dono da postagem", content = @Content)
        @ApiResponse(responseCode = "404", description = "Postagem não encontrada", content = @Content)
        @ApiResponse(responseCode = "500", description = "Erro ao salvar imagem", content = @Content)
    public ResponseEntity<DetailedPostResponse> editPost(@AuthenticationPrincipal LoggedUserPayload user, @PathVariable int postId, @ModelAttribute @Valid EditPostRequest data) throws AccessDeniedException {
        DetailedPostResponse responseData = new DetailedPostResponse(pstSvc.editPost(user, postId, data));
        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }

    // Exclusão de postagem existente
    @DeleteMapping("/{postId}") @PreAuthorize("hasAuthority('post:remove')")
    @Operation(summary = "Excluir uma postagem")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "204", description = "Deletado com sucesso!")
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação, ou não é o dono da postagem", content = @Content)
        @ApiResponse(responseCode = "404", description = "Postagem não encontrada", content = @Content)
    public ResponseEntity<Void> deletePost(@AuthenticationPrincipal LoggedUserPayload user, @PathVariable int postId) throws AccessDeniedException {
        pstSvc.deletePost(user, postId);
        return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
    }
}
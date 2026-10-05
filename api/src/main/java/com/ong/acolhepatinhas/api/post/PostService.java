package com.ong.acolhepatinhas.api.post;

import java.nio.file.AccessDeniedException;
import java.time.OffsetDateTime;
import java.util.Objects;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronization;
import org.springframework.transaction.support.TransactionSynchronizationManager;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.multipart.MultipartFile;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.post.DTO.EditPostRequest;
import com.ong.acolhepatinhas.api.post.DTO.NewPostRequest;
import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.ImageService;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PostService {

    private final PostRepository pstRep;
    private final UserService usrSvc;

    private final ImageService imgSvc;

    // Listagem de postagens com paginação e ordenação
    public Page<Post> listAll(String order, int page, int size) {
        if (page < 0) throw new IllegalArgumentException("Página inválida.");
        if (size < 1 || size > 50) throw new IllegalArgumentException("Tamanho da página deve estar entre 1 e 50.");

        String direction = (order == null || order.isBlank()) ? "desc" : order.trim().toLowerCase();

        Sort.Direction sortDirection = switch (direction) {
            case "asc" -> Sort.Direction.ASC;
            case "desc" -> Sort.Direction.DESC;
            default -> throw new IllegalArgumentException("Ordenação inválida. Use asc ou desc.");
        };

        Sort sort = Sort.by(sortDirection, "createdAt").and(Sort.by(sortDirection, "id"));
        return pstRep.findAll(PageRequest.of(page, size, sort));
    }


    public Post getById(int postId) {
        return pstRep.findById(postId).orElseThrow(() -> new ValueNotFoundException("Postagem não encontrada."));
    }

    // Criação de nova postagem
    @Transactional
    public Post newPost(LoggedUserPayload user, @Valid NewPostRequest data) {

        User requester = (User) usrSvc.loadUserByUsername(user.email());

        String url = this.savePostImage(data.image());

        Post post = Post.builder()
            .user(requester)
            .description(data.description())
            .imageUrl(url)
            .createdAt(OffsetDateTime.now())
            .build();

        return pstRep.save(post);
    }

    // Edição de postagem existente
    @Transactional
    public Post editPost(LoggedUserPayload user, int postId, @Valid EditPostRequest data) throws AccessDeniedException {

        Post post = this.getById(postId);
        User requester = (User) usrSvc.loadUserByUsername(user.email());

        this.assertCanManage(requester, post);

        String previousUrl = post.getImageUrl();
        post.setDescription(data.description());
        this.replaceImage(post, data.image());

        Post saved = pstRep.save(post);
        if (!Objects.equals(previousUrl, saved.getImageUrl())) {
            this.deleteImageAfterCommit(previousUrl);
        }

        return saved;
    }

    // Exclusão de postagem existente
    @Transactional
    public void deletePost(LoggedUserPayload user, int postId) throws AccessDeniedException {

        Post post = this.getById(postId);
        User requester = (User) usrSvc.loadUserByUsername(user.email());

        this.assertCanManage(requester, post);

        String imageUrl = post.getImageUrl();
        pstRep.delete(post);
        this.deleteImageAfterCommit(imageUrl);
    }

    // Salva a imagem da postagem e registra a exclusão em caso de rollback
    private String savePostImage(MultipartFile image) {
        String url = imgSvc.saveImage(new ImageRequest(image), "post", StorageFileType.POST_PHOTO);
        this.deleteImageAfterRollback(url);
        return url;
    }

    // Registra a exclusão da imagem após o commit da transação
    private void deleteImageAfterCommit(String url) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCommit() {
                imgSvc.deleteImage(url, StorageFileType.POST_PHOTO);
            }
        });
    }

    // Registra a exclusão da imagem após o rollback da transação
    private void deleteImageAfterRollback(String url) {
        TransactionSynchronizationManager.registerSynchronization(new TransactionSynchronization() {
            @Override
            public void afterCompletion(int status) {
                if (status == STATUS_ROLLED_BACK) {
                    imgSvc.deleteImage(url, StorageFileType.POST_PHOTO);
                }
            }
        });
    }

    // Substitui a imagem da postagem, se fornecida
    private void replaceImage(Post post, MultipartFile image) {
        if (image == null || image.isEmpty()) return;

        post.setImageUrl(this.savePostImage(image));
    }


    // Admin pode gerenciar qualquer postagem; usuário comum só a própria.
    private void assertCanManage(User requester, Post post) throws AccessDeniedException {
        boolean isOwner = Objects.equals(requester.getId(), post.getUser().getId());
        boolean isAdmin = requester.getRole() == Role.ADMIN;

        if (!isOwner && !isAdmin) throw new AccessDeniedException("Você não tem permissão para gerenciar essa postagem.");
    }
}
package com.ong.acolhepatinhas.api.post.DTO;

import java.util.List;

import org.springframework.data.domain.Page;

import com.ong.acolhepatinhas.api.post.Post;

public record PostPageResponse(

    List<ResumedPostResponse> content,
    int page,
    int size,
    long totalElements,
    int totalPages

) {

    public PostPageResponse(Page<Post> data) {
        this(
            data.getContent().stream().map(ResumedPostResponse::new).toList(),
            data.getNumber(),
            data.getSize(),
            data.getTotalElements(),
            data.getTotalPages()
        );
    }
}

package com.ong.acolhepatinhas.api.post.DTO;

import com.ong.acolhepatinhas.api.post.Post;

public record UpdatablePostData(

    String description,
    String imgUrl
) {

    public static UpdatablePostData fromPost(Post data) {
        return new UpdatablePostData(data.getDescription(), data.getImageUrl());
    }
}

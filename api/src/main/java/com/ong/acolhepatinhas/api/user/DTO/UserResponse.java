package com.ong.acolhepatinhas.api.user.DTO;

import java.time.OffsetDateTime;

import com.ong.acolhepatinhas.api.user.User;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.PositiveOrZero;

public record UserResponse(

    @PositiveOrZero
    Integer id,

    @NotBlank
    String name,

    @NotBlank
    String email,

    @NotNull
    OffsetDateTime createdAt
) {

    public static UserResponse from(User user) {
        if (user == null) return null;

        return new UserResponse(user.getId(), user.getName(), user.getEmail(), user.getCreatedAt());
    } 
}

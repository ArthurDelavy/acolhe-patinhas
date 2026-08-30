package com.ong.acolhepatinhas.api.security.enums;

public enum Permission {
    ANIMAL_READ("animal:read"),
    ANIMAL_CREATE("animal:create"),
    ANIMAL_EDIT("animal:edit"),
    ANIMAL_REMOVE("animal:remove"),

    ANIMAL_REFERENCE_MANAGE("animalReference:manage");



    private final String permission;

    Permission(String permission) {
        this.permission = permission;
    }

    public String getPermission() {
        return permission;
    }
}

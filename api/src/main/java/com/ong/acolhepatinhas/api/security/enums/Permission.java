package com.ong.acolhepatinhas.api.security.enums;

public enum Permission {
    ANIMAL_READ("animal:read");



    private final String permission;

    Permission(String permission) {
        this.permission = permission;
    }

    public String getPermission() {
        return permission;
    }
}

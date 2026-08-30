package com.ong.acolhepatinhas.api.security.enums;

import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

import org.springframework.security.core.authority.SimpleGrantedAuthority;

public enum Role {
    ADMIN(Set.of(
        Permission.ANIMAL_READ,
        Permission.ANIMAL_CREATE,
        Permission.ANIMAL_EDIT,
        Permission.ANIMAL_REFERENCE_MANAGE
    )),

    USER(Set.of(
        Permission.ANIMAL_READ
    ));



    private final Set<Permission> permissions;

    Role(Set<Permission> permissions) {
        this.permissions = permissions;
    }



    public List<SimpleGrantedAuthority> getAuthorities() {
        
        List<SimpleGrantedAuthority> authorities = permissions.stream()
            .map(permission -> new SimpleGrantedAuthority(permission.getPermission()))
            .collect(Collectors.toList());

        authorities.add(new SimpleGrantedAuthority("ROLE_" + this.name()));

        return authorities;
    }
}

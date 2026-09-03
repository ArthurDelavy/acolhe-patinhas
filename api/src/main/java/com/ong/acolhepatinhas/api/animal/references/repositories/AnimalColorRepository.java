package com.ong.acolhepatinhas.api.animal.references.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;

@Repository
public interface AnimalColorRepository extends JpaRepository<AnimalColor, Integer> {
    boolean existsByName(String name);
}

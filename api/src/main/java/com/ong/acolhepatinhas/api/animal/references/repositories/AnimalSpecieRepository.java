package com.ong.acolhepatinhas.api.animal.references.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

@Repository
public interface AnimalSpecieRepository extends JpaRepository<AnimalSpecie, Integer> {

    List<AnimalSpecie> findAll();

    boolean existsByName(String name);
}
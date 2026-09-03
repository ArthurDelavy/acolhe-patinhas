package com.ong.acolhepatinhas.api.animal.references.repositories;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

@Repository
public interface AnimalBreedRepository extends JpaRepository<AnimalBreed, Integer> {

    @EntityGraph(attributePaths = {"specie"})
    List<AnimalBreed> findAll();

    boolean existsByNameAndSpecie(String name, AnimalSpecie specie);    
}

package com.ong.acolhepatinhas.api.animal.references.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

@Repository
public interface AnimalBreedRepository extends JpaRepository<AnimalBreed, Integer> {
    
}

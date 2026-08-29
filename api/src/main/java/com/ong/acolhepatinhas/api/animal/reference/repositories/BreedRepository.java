package com.ong.acolhepatinhas.api.animal.reference.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.reference.entities.Breed;

@Repository
public interface BreedRepository extends JpaRepository<Breed, Integer> {
    
}

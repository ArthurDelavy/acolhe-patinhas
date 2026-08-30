package com.ong.acolhepatinhas.api.animal;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;

public interface AnimalRepository extends JpaRepository<Animal, Integer> {
    boolean existsByBreed(AnimalBreed breed);
}

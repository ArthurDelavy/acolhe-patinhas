package com.ong.acolhepatinhas.api.animal;

import org.springframework.data.jpa.repository.JpaRepository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;

public interface AnimalRepository extends JpaRepository<Animal, Integer> {
    boolean existsByBreed(AnimalBreed breed);
    boolean existsBySpecie(AnimalSpecie specie);
    boolean existsByColor(AnimalColor color);
    boolean existsByDischargeReason(AnimalDischargeReason dischargeReason);
}

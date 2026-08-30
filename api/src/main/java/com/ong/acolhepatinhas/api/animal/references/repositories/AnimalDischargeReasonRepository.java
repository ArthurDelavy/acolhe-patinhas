package com.ong.acolhepatinhas.api.animal.references.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;

@Repository
public interface AnimalDischargeReasonRepository extends JpaRepository<AnimalDischargeReason, Integer> {
    boolean existsByName(String name);
}
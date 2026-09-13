package com.ong.acolhepatinhas.api.veterinary.disease.catalog;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DiseaseRepository extends JpaRepository<Disease, Integer> {
    boolean existsByName(String name);
}

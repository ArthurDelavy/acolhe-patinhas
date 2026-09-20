package com.ong.acolhepatinhas.api.veterinary.labtest.catalog;

import org.springframework.data.jpa.repository.JpaRepository;

public interface LaboratoryTestRepository extends JpaRepository<LaboratoryTest, Integer>{
    boolean existsByName(String name);
}

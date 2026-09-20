package com.ong.acolhepatinhas.api.veterinary.surgery.catalog;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SurgicalprocedureRepository extends JpaRepository<SurgicalProcedure, Integer>{
    boolean existsByName(String name);
}

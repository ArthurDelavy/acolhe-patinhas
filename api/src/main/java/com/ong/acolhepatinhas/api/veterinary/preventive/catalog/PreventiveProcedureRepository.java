package com.ong.acolhepatinhas.api.veterinary.preventive.catalog;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface PreventiveProcedureRepository extends JpaRepository<PreventiveProcedure, Integer>{
    boolean existsByName(String name);
}

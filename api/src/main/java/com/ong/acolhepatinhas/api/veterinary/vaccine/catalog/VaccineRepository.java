package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface VaccineRepository extends JpaRepository<Vaccine, Integer> {
    
    boolean existsByName(String name);
}

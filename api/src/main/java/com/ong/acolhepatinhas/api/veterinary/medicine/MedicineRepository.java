package com.ong.acolhepatinhas.api.veterinary.medicine;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface MedicineRepository extends JpaRepository<Medicine, Integer>{
    boolean existsByName(String name);
}

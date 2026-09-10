package com.ong.acolhepatinhas.api.veterinary.record;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.Animal;

@Repository
public interface VeterinaryRecordRepository extends JpaRepository<VeterinaryRecord, Integer> {
    Optional<VeterinaryRecord> findByAnimal(Animal animal);
}

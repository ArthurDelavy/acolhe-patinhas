package com.ong.acolhepatinhas.api.veterinary.treatment.record;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface TreatmentRepository extends JpaRepository<Treatment, Integer> {
    
    @EntityGraph(attributePaths = {"diagnosis.disease", "vetRecord.animal"})
    List<Treatment> findAll();

    @EntityGraph(attributePaths = {"diagnosis.disease", "vetRecord.animal"})
    List<Treatment> findAllByVetRecord_Animal_Id(int animalId);
}

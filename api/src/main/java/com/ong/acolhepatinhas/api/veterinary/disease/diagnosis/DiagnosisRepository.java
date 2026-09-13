package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis;

import java.util.List;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.veterinary.disease.catalog.Disease;

@Repository
public interface DiagnosisRepository extends JpaRepository<Diagnosis, Integer>{
    boolean existsByDisease(Disease disease);

    @EntityGraph(attributePaths = {"disease", "vetRecord.animal"})
    List<Diagnosis> findAll();

    @EntityGraph(attributePaths = {"disease", "vetRecord.animal"})
    List<Diagnosis> findById(int id);

    @EntityGraph(attributePaths = {"disease", "vetRecord.animal"})
    List<Diagnosis> findAllByVetRecord_Animal_Id(int animalId);
}
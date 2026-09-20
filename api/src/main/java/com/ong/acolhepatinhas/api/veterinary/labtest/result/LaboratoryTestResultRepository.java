package com.ong.acolhepatinhas.api.veterinary.labtest.result;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.LaboratoryTest;

@Repository
public interface LaboratoryTestResultRepository extends JpaRepository<LaboratoryTestResult, Integer>{
    boolean existsByLabTest(LaboratoryTest labTest);

    @EntityGraph(attributePaths = {"vetRecord.animal", "labTest"})
    Optional<LaboratoryTestResult> findById(int id);
    
    @EntityGraph(attributePaths = {"vetRecord.animal", "labTest"})
    List<LaboratoryTestResult> findAll();

    @EntityGraph(attributePaths = {"vetRecord.animal", "labTest"})
    List<LaboratoryTestResult> findAllByVetRecord_Animal_Id(int animalId);
}

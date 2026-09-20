package com.ong.acolhepatinhas.api.veterinary.surgery.procedure;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.ong.acolhepatinhas.api.veterinary.surgery.catalog.SurgicalProcedure;

public interface SurgeryRepository extends JpaRepository<Surgery, Integer>{
    boolean existsBySurgicalProcedure(SurgicalProcedure procedure);

    @EntityGraph(attributePaths = {"vetRecord.animal", "surgicalProcedure"})
    Optional<Surgery> findById(int id);
    
    @EntityGraph(attributePaths = {"vetRecord.animal", "surgicalProcedure"})
    List<Surgery> findAll();

    @EntityGraph(attributePaths = {"vetRecord.animal", "surgicalProcedure"})
    List<Surgery> findAllByVetRecord_Animal_Id( int animalId);
}

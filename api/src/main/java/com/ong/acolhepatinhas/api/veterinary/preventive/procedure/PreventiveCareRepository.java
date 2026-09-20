package com.ong.acolhepatinhas.api.veterinary.preventive.procedure;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.PreventiveProcedure;

@Repository
public interface PreventiveCareRepository extends JpaRepository<PreventiveCare, Integer> {
    boolean existsByPreventiveProcedure(PreventiveProcedure procedure);

    @EntityGraph(attributePaths = {"vetRecord.animal", "procedure", "medicine"})
    Optional<PreventiveCare> findById(int id);
    
    @EntityGraph(attributePaths = {"vetRecord.animal", "procedure", "medicine"})
    List<PreventiveCare> findAll();

    @EntityGraph(attributePaths = {"vetRecord.animal", "procedure", "medicine"})
    List<PreventiveCare> findAllByVetRecord_Animal_Id( int animalId);
}
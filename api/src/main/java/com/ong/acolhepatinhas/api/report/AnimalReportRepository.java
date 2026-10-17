package com.ong.acolhepatinhas.api.report;

import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface AnimalReportRepository extends JpaRepository<AnimalReport, Integer>{
    
    @EntityGraph(attributePaths = {"user"})
    Optional<AnimalReport> findById(int id);
}

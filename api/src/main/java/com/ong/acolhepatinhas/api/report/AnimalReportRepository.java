package com.ong.acolhepatinhas.api.report;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;


@Repository
public interface AnimalReportRepository extends JpaRepository<AnimalReport, Integer>{
    
}

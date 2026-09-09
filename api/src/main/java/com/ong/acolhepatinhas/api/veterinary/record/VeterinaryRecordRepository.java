package com.ong.acolhepatinhas.api.veterinary.record;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface VeterinaryRecordRepository extends JpaRepository<VeterinaryRecord, Integer> {
    
}

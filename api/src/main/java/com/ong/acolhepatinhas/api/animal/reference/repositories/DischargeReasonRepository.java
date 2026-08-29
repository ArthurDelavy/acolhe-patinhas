package com.ong.acolhepatinhas.api.animal.reference.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.animal.reference.entities.DischargeReason;

@Repository
public interface DischargeReasonRepository extends JpaRepository<DischargeReason, Integer> {
}

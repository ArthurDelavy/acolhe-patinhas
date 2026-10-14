package com.ong.acolhepatinhas.api.term.agreement;

import org.springframework.data.jpa.repository.JpaRepository;

public interface TermAgreementRepository extends JpaRepository<TermAgreement, Integer>{
    boolean existsByUserIdAndTermVersionId(int userId, int termVersionId);
}

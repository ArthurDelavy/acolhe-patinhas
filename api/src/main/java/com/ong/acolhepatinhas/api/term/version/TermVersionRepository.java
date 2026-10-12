package com.ong.acolhepatinhas.api.term.version;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

public interface TermVersionRepository extends JpaRepository<TermVersion, Integer> {
    Optional<TermVersion> findByIsCurrentTrue();
}

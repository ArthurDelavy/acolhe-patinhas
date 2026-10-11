package com.ong.acolhepatinhas.api.fosterhome;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository 
public interface FosterHomeRepository extends JpaRepository<FosterHome, Integer> {
    
    boolean existsByName(String name);


    @EntityGraph(attributePaths = {"user", "owner"})
    List<FosterHome> findAll();

    @EntityGraph(attributePaths = {"user", "owner"})
    Optional<FosterHome> findById();
}

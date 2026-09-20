package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.Vaccine;

@Repository
public interface VaccinationRepository extends JpaRepository<Vaccination, Integer> {
    boolean existsByVaccine(Vaccine vaccine);

    @EntityGraph(attributePaths = {"vaccine", "vetRecord.animal"})
    List<Vaccination> findAllByVetRecord_Animal_Id(int animalId);

    @EntityGraph(attributePaths = {"vaccine", "vetRecord.animal"})
    List<Vaccination> findAll();

    @EntityGraph(attributePaths = {"vaccine", "vetRecord.animal"})
    Optional<Vaccination> findById(int id);
}

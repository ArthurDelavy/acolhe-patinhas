package com.ong.acolhepatinhas.api.veterinary.treatment.posology;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;

import com.ong.acolhepatinhas.api.veterinary.medicine.Medicine;

public interface TreatmentMedicineRepository extends JpaRepository<TreatmentMedicine, Integer>{
    boolean existsByMedicine(Medicine medicine);

    @EntityGraph(attributePaths = {"treatment", "medicine"})
    List<TreatmentMedicine> findAll();

    @EntityGraph(attributePaths = {"treatment", "medicine"})
    Optional<TreatmentMedicine> findById(int id);

    @EntityGraph(attributePaths = {"treatment", "medicine"})
    List<TreatmentMedicine> findAllByTreatment_id(int treatmentId);

}

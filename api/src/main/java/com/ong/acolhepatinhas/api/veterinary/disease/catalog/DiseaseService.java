package com.ong.acolhepatinhas.api.veterinary.disease.catalog;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.disease.catalog.DTO.NewDiseaseRequest;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DiagnosisService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DiseaseService {
    
    private final DiseaseRepository dseRep;

    private final DiagnosisService dgnSvc;


    public List<Disease> listAll() {
        return dseRep.findAll();
    }

    public Disease getById(int diseaseId) {
        return dseRep.findById(diseaseId).orElseThrow(() -> new ValueNotFoundException("Doença não encontrada."));
    }


    @Transactional 
    public Disease newDisease(@Valid NewDiseaseRequest data) {

        if (dseRep.existsByName(data.name())) throw new DuplicatedValueException("Doença já cadastrada.");

        Disease disease = Disease.builder()
            .name(data.name())
            .build();

        return dseRep.save(disease);
    }


    @Transactional
    public void deleteDisease(int diseaseId) {
        Disease disease = this.getById(diseaseId);
        if (dgnSvc.existsByDisease(disease)) throw new ResourceInUseException("A doença não pôde ser deletada pois está vinculada a um diagnóstico.");

        dseRep.delete(disease);
    }
}

package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis;

import java.util.List;

import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.disease.catalog.Disease;
import com.ong.acolhepatinhas.api.veterinary.disease.catalog.DiseaseService;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO.NewDiagnosisRequest;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DTO.UpdateDiagnosisStatusRequest;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class DiagnosisService {
    
    private final DiagnosisRepository dgnRep;
    
    private final VeterinaryRecordService vtrSvc;

    @Lazy
    private final DiseaseService dseSvc;


    public boolean existsByDisease(Disease disease) {
        return dgnRep.existsByDisease(disease);
    }

    public List<Diagnosis> listAll() {
        return dgnRep.findAll();
    }

    public List<Diagnosis> listAllByAnimal(int animalId) {
        return dgnRep.findAllByVetRecord_Animal_Id(animalId);
    }

    public Diagnosis getById(int diagnosisId) {
        return dgnRep.findById(diagnosisId).orElseThrow(() -> new ValueNotFoundException("Diagnóstico não encontrado."));
    }


    @Transactional
    public Diagnosis newDiagnosis(int animalId, @Valid NewDiagnosisRequest data) {
        
        VeterinaryRecord vetRecord = vtrSvc.getById(animalId);
        Disease disease = dseSvc.getById(data.diseaseId());

        Diagnosis diagnosis = Diagnosis.builder()
            .vetRecord(vetRecord)
            .disease(disease)
            .diagnosedAt(data.diagnosedAt())
            .status(data.status())
            .build();

        return dgnRep.save(diagnosis);
    }

    
    @Transactional
    public Diagnosis changeStatus(int diagnosisId, @Valid UpdateDiagnosisStatusRequest data) {

        Diagnosis diagnosis = this.getById(diagnosisId);

        diagnosis.setStatus(data.status());
        return dgnRep.save(diagnosis);
    }


    @Transactional
    public void deleteDiagnosis(int diagnosisId) {

        Diagnosis diagnosis = this.getById(diagnosisId);
        dgnRep.delete(diagnosis);
    }
}

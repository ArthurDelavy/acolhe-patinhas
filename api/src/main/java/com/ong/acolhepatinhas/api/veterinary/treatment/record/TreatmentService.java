package com.ong.acolhepatinhas.api.veterinary.treatment.record;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.Diagnosis;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.DiagnosisService;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.EditTreatmentRequest;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.DTO.NewTreatmentRequest;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TreatmentService {

    private final TreatmentRepository ttmRep;

    private final VeterinaryRecordService vrcSvc;
    private final DiagnosisService dgnSvc;
    

    public List<Treatment> listAllByAnimal(int animalId) {
        return ttmRep.findAllByVetRecord_Animal_Id(animalId);
    }

    public List<Treatment> listAll() {
        return ttmRep.findAll();
    }

    public Treatment getById(int treatmentId) {
        return ttmRep.findById(treatmentId).orElseThrow(() -> new ValueNotFoundException("Tratamento não encontrado."));
    }


    @Transactional
    public Treatment newTreatment(int animalId, @Valid NewTreatmentRequest data) {

        VeterinaryRecord vetRecord = vrcSvc.getById(animalId);
        Diagnosis diagnosis = data.diagnosisId() != null ? dgnSvc.getById(data.diagnosisId()) : null;

        Treatment treatment = Treatment.builder()
            .vetRecord(vetRecord)
            .diagnosis(diagnosis)
            .startDate(data.startDate())
            .endDate(data.endDate())
            .status(data.status())
            .observations(data.observations())
            .build();

        return ttmRep.save(treatment);
    }


    @Transactional
    public Treatment editTreatment(int treatmentId, @Valid EditTreatmentRequest data) {

        Treatment treatment = this.getById(treatmentId);
        Diagnosis diagnosis = data.diagnosisId() != null ? dgnSvc.getById(data.diagnosisId()) : null;

        treatment.setDiagnosis(diagnosis);
        treatment.setStartDate(data.startDate());
        treatment.setEndDate(data.endDate());
        treatment.setStatus(data.status());
        treatment.setObservations(data.observations());

        return ttmRep.save(treatment);
    }


    @Transactional
    public void deleteTreatment(int treatmentId) {

        Treatment treatment = this.getById(treatmentId);
        ttmRep.delete(treatment);
    }
}

package com.ong.acolhepatinhas.api.veterinary.treatment.record;

import java.util.List;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.utils.ObjectComparator;
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

    private final ApplicationEventPublisher evtPbs;
    private final ObjectComparator objCpr;
    

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

        Treatment newTreatment = ttmRep.save(treatment);

        evtPbs.publishEvent(new AuditLogEvent(
            "TREATMENT_CREATED",
            "Treatment/%d".formatted(newTreatment.getId()),
            null
        ));

        return newTreatment;
    }


    @Transactional
    public Treatment editTreatment(int treatmentId, @Valid EditTreatmentRequest data) {

        Treatment treatment = this.getById(treatmentId);
        Diagnosis diagnosis = data.diagnosisId() != null ? dgnSvc.getById(data.diagnosisId()) : null;

        EditTreatmentRequest oldData = EditTreatmentRequest.fromTreatment(treatment);

        treatment.setDiagnosis(diagnosis);
        treatment.setStartDate(data.startDate());
        treatment.setEndDate(data.endDate());
        treatment.setStatus(data.status());
        treatment.setObservations(data.observations());

        Treatment newTreatment = ttmRep.save(treatment);

        evtPbs.publishEvent(new AuditLogEvent(
            "TREATMENT_EDITED",
            "Treatment/%d".formatted(newTreatment.getId()),
            objCpr.getDifferentAttributes(oldData, data)
        ));

        return newTreatment;
    }


    @Transactional
    public void deleteTreatment(int treatmentId) {

        Treatment treatment = this.getById(treatmentId);
        ttmRep.delete(treatment);

        evtPbs.publishEvent(new AuditLogEvent(
            "TREATMENT_DELETED",
            "Treatment/%d".formatted(treatment.getId()),
            """
            {
                "deletedRecord": {
                    "animalId": %d,
                    "diagnosisId": %d,
                    "disease": "%s"
                }
            }
            """.formatted(treatment.getVetRecord().getId(), treatment.getDiagnosis().getId(), treatment.getDiagnosis().getDisease().getName())
        ));
    }
}

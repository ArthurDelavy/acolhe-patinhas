package com.ong.acolhepatinhas.api.veterinary.labtest.result;

import java.util.List;

import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.LaboratoryTest;
import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.LaboratoryTestService;
import com.ong.acolhepatinhas.api.veterinary.labtest.result.DTO.NewLaboratoryTestResultRequest;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class LaboratoryTestResultService {
    
    private final LaboratoryTestResultRepository ltrRep;

    private final VeterinaryRecordService vtrSvc;
    private final LaboratoryTestService lbtSvc;

    private final ApplicationEventPublisher evtPbs;



    public boolean existsByLabTest(LaboratoryTest labTest) {
        return ltrRep.existsByLabTest(labTest);
    }

    
    public LaboratoryTestResult getById(int labTestId) {
        return ltrRep.findById(labTestId).orElseThrow(() -> new ValueNotFoundException("Teste laboratorial não encontrado."));
    }

    public List<LaboratoryTestResult> listAll() {
        return ltrRep.findAll();
    }

    public List<LaboratoryTestResult> listAllByAnimal(int animalId) {
        return ltrRep.findAllByVetRecord_Animal_Id(animalId);
    }


    @Transactional
    public LaboratoryTestResult newLabTest(int animalId, @Valid NewLaboratoryTestResultRequest data) {
        
        VeterinaryRecord vetRecord = vtrSvc.getById(animalId);
        LaboratoryTest labTest = lbtSvc.getById(data.labTestId());

        LaboratoryTestResult testResult = LaboratoryTestResult.builder()
            .vetRecord(vetRecord)
            .labTest(labTest)
            .testDate(data.testDate())
            .results(data.results())
            .observations(data.observations())
            .build();

        LaboratoryTestResult newResult = ltrRep.save(testResult);

        evtPbs.publishEvent(new AuditLogEvent(
            "LAB_TEST_RESULT_CREATED",
            "Result/%d".formatted(newResult.getId()),
            null
        ));

        return newResult;
    }

    @Transactional
    public void deleteLabTest(int labTestId) {

        LaboratoryTestResult testResult = this.getById(labTestId);
        ltrRep.delete(testResult);


        evtPbs.publishEvent(new AuditLogEvent(
            "LAB_TEST_RESULT_DELETED",
            "Result/%d".formatted(testResult.getId()),
            """
            {
                "deletedRecord": {
                    "animalId": %d,
                    "testType": "%s",
                    "result": "%s"
                }
            }
            """.formatted(testResult.getVetRecord().getId(), testResult.getLabTest().getName(), testResult.getResults())
        ));
    }
}

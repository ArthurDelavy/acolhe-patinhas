package com.ong.acolhepatinhas.api.veterinary.surgery.procedure;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;
import com.ong.acolhepatinhas.api.veterinary.surgery.catalog.SurgicalProcedure;
import com.ong.acolhepatinhas.api.veterinary.surgery.catalog.SurgicalProcedureService;
import com.ong.acolhepatinhas.api.veterinary.surgery.procedure.DTO.NewSurgeryRequest;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SurgeryService {
    
    private final SurgeryRepository srgRep;

    private final SurgicalProcedureService sgpSvc;
    private final VeterinaryRecordService vtrSvc;


    public boolean existsBySurgicalProcedure(SurgicalProcedure procedure) {
        return srgRep.existsBySurgicalProcedure(procedure);
    }

    
    public Surgery getById(int surgeryId) {
        return srgRep.findById(surgeryId).orElseThrow(() -> new ValueNotFoundException("Cirurgia não encontrada."));
    }

    public List<Surgery> listAll() {
        return srgRep.findAll();
    }

    public List<Surgery> listAllByAnimal(int animalId) {
        return srgRep.findAllByVetRecord_Animal_Id(animalId);
    }


    @Transactional
    public Surgery newSurgery(int animalId, @Valid NewSurgeryRequest data) {
        
        VeterinaryRecord vetRecord = vtrSvc.getById(animalId);
        SurgicalProcedure procedure = sgpSvc.getById(data.procedureId());

        Surgery surgery = Surgery.builder()
            .vetRecord(vetRecord)
            .surgicalProcedure(procedure)
            .procedureDate(data.procedureDate())
            .observations(data.observations())
            .build();

        return srgRep.save(surgery);
    }

    @Transactional
    public void deleteSurgery(int surgeryId) {

        Surgery surgery = this.getById(surgeryId);
        srgRep.delete(surgery);
    }
}

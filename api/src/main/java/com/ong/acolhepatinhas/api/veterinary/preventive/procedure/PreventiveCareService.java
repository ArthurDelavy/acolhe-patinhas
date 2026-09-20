package com.ong.acolhepatinhas.api.veterinary.preventive.procedure;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.medicine.Medicine;
import com.ong.acolhepatinhas.api.veterinary.medicine.MedicineService;
import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.PreventiveProcedure;
import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.PreventiveProcedureService;
import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.DTO.NewPreventiveCareRequest;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class PreventiveCareService {
    
    private final PreventiveCareRepository pvcRep;

    private final VeterinaryRecordService vtrSvc;
    private final PreventiveProcedureService pvpSvc;
    private final MedicineService mdcSvc;

    public boolean existsBySurgicalProcedure(PreventiveProcedure procedure) {
        return pvcRep.existsByPreventiveProcedure(procedure);
    }

    
    public PreventiveCare getById(int preventiveId) {
        return pvcRep.findById(preventiveId).orElseThrow(() -> new ValueNotFoundException("Preventiva não encontrada."));
    }

    public List<PreventiveCare> listAll() {
        return pvcRep.findAll();
    }

    public List<PreventiveCare> listAllByAnimal(int animalId) {
        return pvcRep.findAllByVetRecord_Animal_Id(animalId);
    }


    @Transactional
    public PreventiveCare newPreventive(int animalId, @Valid NewPreventiveCareRequest data) {
        
        VeterinaryRecord vetRecord = vtrSvc.getById(animalId);
        PreventiveProcedure procedure = pvpSvc.getById(data.procedureId());
        Medicine medicine = data.medicineId() != null ? mdcSvc.getById(data.medicineId()) : null;

        PreventiveCare preventive = PreventiveCare.builder()
            .vetRecord(vetRecord)
            .procedure(procedure)
            .medicine(medicine)
            .procedureDate(data.procedureDate())
            .nextProcedureDate(data.nextProcedureDate())
            .observations(data.observations())
            .build();

        return pvcRep.save(preventive);
    }

    @Transactional
    public void deletePreventive(int preventiveId) {

        PreventiveCare preventive = this.getById(preventiveId);
        pvcRep.delete(preventive);
    }
}

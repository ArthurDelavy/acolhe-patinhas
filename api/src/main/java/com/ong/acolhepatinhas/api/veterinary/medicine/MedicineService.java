package com.ong.acolhepatinhas.api.veterinary.medicine;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.veterinary.medicine.DTO.NewMedicineRequest;
import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.PreventiveCareService;
import com.ong.acolhepatinhas.api.veterinary.treatment.posology.TreatmentMedicineService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Validated
@Transactional(readOnly = true)
public class MedicineService {
    
    private final MedicineRepository mdcRep;

    @Autowired @Lazy
    private TreatmentMedicineService tmcSvc;
    private final PreventiveCareService pvcSvc;


    private final ApplicationEventPublisher evtPbs;


    @Cacheable(value = "medicines")
    public List<Medicine> listAll() {
        return mdcRep.findAll();
    }

    @Cacheable(value = "medicine", key = "#medicineId")
    public Medicine getById(int medicineId) {
        return mdcRep.findById(medicineId).orElseThrow(() -> new ValueNotFoundException("Medicamento não encontrado."));
    }


    @Transactional
    @CacheEvict(value = "medicines", allEntries = true)
    public Medicine newMedicine(@Valid NewMedicineRequest data) {

        if (mdcRep.existsByName(data.name())) throw new DuplicatedValueException("Medicamento já cadastrado.");

        Medicine medicine = Medicine.builder()
            .name(data.name())
            .build();

        Medicine newMedicine = mdcRep.save(medicine); 


        evtPbs.publishEvent(new AuditLogEvent(
            "MEDICINE_CREATED",
            "Medicine/%d".formatted(newMedicine.getId()),
            null
        ));

        return newMedicine;
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "medicines", allEntries = true),
        @CacheEvict(value = "medicine", key = "#medicineId")
    })
    public void deleteMedicine(int medicineId) {

        Medicine medicine = this.getById(medicineId);

        if (tmcSvc.existsByMedicine(medicine)) throw new ResourceInUseException("O medicamento não pôde ser deletado pois está vinculado a um tratamento.");
        if (pvcSvc.existsByMedicine(medicine)) throw new ResourceInUseException("O medicamento não pôde ser deletado pois está vinculado a um cuidado preventivo.");

        mdcRep.delete(medicine);


        evtPbs.publishEvent(new AuditLogEvent(
            "MEDICINE_DELETED",
            "Medicine/%d".formatted(medicine.getId()),
            """
            {
                "deletedRecord": {
                    "name": "%s"
                }
            }
            """.formatted(medicine.getName())
        ));
    }
}

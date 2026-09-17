package com.ong.acolhepatinhas.api.veterinary.treatment.posology;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.medicine.Medicine;
import com.ong.acolhepatinhas.api.veterinary.medicine.MedicineService;
import com.ong.acolhepatinhas.api.veterinary.treatment.posology.DTO.NewPosologyRequest;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.Treatment;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.TreatmentService;

import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TreatmentMedicineService {

    private final TreatmentMedicineRepository tmdRep;

    private final TreatmentService ttmSvc;
    private final MedicineService mdcSvc;
    


    public boolean existsByMedicine(Medicine medicine) {
        return tmdRep.existsByMedicine(medicine);
    }

    public List<TreatmentMedicine> listAll() {
        return tmdRep.findAll();
    }

    public TreatmentMedicine getById(int treatmentMedicineId) {
        return tmdRep.findById(treatmentMedicineId).orElseThrow(() -> new ValueNotFoundException("Administração de medicamento não encontrada."));
    }

    public List<TreatmentMedicine> listAllByTreatment(int treatmentId) {
        return tmdRep.findAllByTreatment_id(treatmentId);
    }



    @Transactional
    public TreatmentMedicine newPosology(int treatmentId, NewPosologyRequest data) {

        Treatment treatment = ttmSvc.getById(treatmentId);
        Medicine medicine = mdcSvc.getById(data.medicineId());

        TreatmentMedicine posology = TreatmentMedicine.builder()
            .treatment(treatment)
            .medicine(medicine)
            .dosage(data.dosage())
            .frequency(data.frequency())
            .durationDays(data.durationDays())
            .startDate(data.starDate())
            .build();

        return tmdRep.save(posology);
    }
    

    @Transactional 
    public void deleteAdministration(int treatmentMedicineId) {

        TreatmentMedicine posology = this.getById(treatmentMedicineId);
        tmdRep.delete(posology);
    }
}   

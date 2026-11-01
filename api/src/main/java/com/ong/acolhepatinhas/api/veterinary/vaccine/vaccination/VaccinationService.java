package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.context.annotation.Lazy;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecordService;
import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.Vaccine;
import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.VaccineService;
import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.DTO.NewVaccinationRequest;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor 
@Transactional(readOnly = true)
public class VaccinationService {
    
    private final VaccinationRepository vctRep;

    private final VeterinaryRecordService vrcSvc;
    @Autowired @Lazy
    private VaccineService vccSvc;


    private final ApplicationEventPublisher evtPbs;



    public boolean existsByVaccine(Vaccine vaccine) {
        return vctRep.existsByVaccine(vaccine);
    }



    public List<Vaccination> listAllByAnimal(int animalId) {
        return vctRep.findAllByVetRecord_Animal_Id(animalId);
    }

    public List<Vaccination> listAll() {
        return vctRep.findAll();
    }

    public Vaccination getById(int vaccinationId) {
        return vctRep.findById(vaccinationId).orElseThrow(() -> new ValueNotFoundException("Vacinação não encontrada."));
    }

    

    @Transactional
    public Vaccination newVaccination(int animalId, @Valid NewVaccinationRequest data) {

        Vaccination vaccination = Vaccination.builder()
            .vetRecord(vrcSvc.getById(animalId))
            .vaccine(vccSvc.getById(data.vaccineId()))
            .dose(data.dose())
            .manufacturer(data.manufacturer())
            .batchNumber(data.batchNumer())
            .vaccinationDate(data.vaccinationDate())
            .nextDoseDate(data.nextDoseDate())
            .build();

        Vaccination newVaccination = vctRep.save(vaccination);

        evtPbs.publishEvent(new AuditLogEvent(
            "VACCINATION_CREATED",
            "Vaccination/%d".formatted(vaccination.getId()),
            null
        ));

        return newVaccination;
    }

    @Transactional
    public void deleteVaccination(int vaccinationId) {

        Vaccination vaccination = getById(vaccinationId);
        vctRep.delete(vaccination);

        evtPbs.publishEvent(new AuditLogEvent(
            "VACCINATION_DELETED",
            "Vaccination/%d".formatted(vaccination.getId()),
            """
            {
                "deletedRecord": {
                    "animalId": %d,
                    "vaccine": "%s",
                    "dose": "%s",
                    "manufacturer": "%s",
                    "batchNumber": "%s",
                }
            }
            """.formatted(vaccination.getVetRecord().getId(), vaccination.getVaccine().getName(), vaccination.getDose(), vaccination.getManufacturer(), vaccination.getBatchNumber())
        ));
    }
}

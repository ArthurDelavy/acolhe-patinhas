package com.ong.acolhepatinhas.api.veterinary.record;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.animal.Animal;
import com.ong.acolhepatinhas.api.animal.AnimalService;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.record.DTO.NewVetRecordRequest;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor 
@Transactional(readOnly = true)
public class VeterinaryRecordService {
    
    private final VeterinaryRecordRepository vetRep;
    private final AnimalService anmSvc;

    public VeterinaryRecord getById(int recordId) {
        return vetRep.findById(recordId).orElseThrow(() -> new ValueNotFoundException("Registro veterinário não encontrado."));
    }



    public VeterinaryRecord newRecord(int animalId, @Valid NewVetRecordRequest data) {

        Animal animal = anmSvc.getById(animalId);
        
        VeterinaryRecord record = VeterinaryRecord.builder()
            .animal(animal)
            .size(data.size())
            .weight(data.weight())
            .neutered(data.neutered())
            .build();

        return vetRep.save(record);
    }
}

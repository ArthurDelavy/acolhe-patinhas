package com.ong.acolhepatinhas.api.animal;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.animal.DTO.NewAnimalRequest;
import com.ong.acolhepatinhas.api.animal.references.ReferencesService;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AnimalService {
    
    private final AnimalRepository anmRep;
    private final UserService usrSvc;
    private final ReferencesService rfcSvc;


    public List<Animal> listAll() {
        return anmRep.findAll();
    }


    public Animal getById(int animalId) {
        return anmRep.findById(animalId).orElseThrow(() -> new ValueNotFoundException("Animal não encontrado."));
    }


    @Transactional
    public Animal newAnimal(LoggedUserPayload user, @Valid NewAnimalRequest data) {
        
        if (anmRep.existsByMicrochipNumber(data.microchipNumber())) throw new DuplicatedValueException("Animal já cadastrado.");

        User requester = (User) usrSvc.loadUserByUsername(user.email());

        Animal animal = Animal.builder()
            .user(requester)
            .name(data.name())
            .microchipNumber(data.microchipNumber())
            .breed(rfcSvc.getBreed(data.breedId()))
            .color(rfcSvc.getColor(data.colorId()))
            .gender(data.gender())
            .birthDate(data.birthDate())
            .intakeDate(data.intakeDate())
            .toAdoption(data.toAdoption())
            .build();

        return anmRep.save(animal);
    }
}

package com.ong.acolhepatinhas.api.animal;

import java.util.List;
import java.util.Objects;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.animal.DTO.EditAnimalRequest;
import com.ong.acolhepatinhas.api.animal.DTO.NewAnimalRequest;
import com.ong.acolhepatinhas.api.animal.references.ReferencesService;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.services.ImageService;
import com.ong.acolhepatinhas.api.services.DTO.ImageRequest;
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

    private final ImageService imgSvc;


    public List<Animal> listAll(Boolean toAdoption) {
        if (toAdoption != null) anmRep.findAllByToAdoption(toAdoption);
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


    @Transactional
    public Animal editAnimal(LoggedUserPayload user, int animalId, @Valid EditAnimalRequest data) {

        Animal animal = this.getById(animalId);
        User requester = (User) usrSvc.loadUserByUsername(user.email());
        
        if (
            data.microchipNumber() != null &&
            !Objects.equals(animal.getMicrochipNumber(), data.microchipNumber()) &&
            anmRep.existsByMicrochipNumber(data.microchipNumber())
        ) throw new DuplicatedValueException("Animal já cadastrado.");
        
        if (data.dischargeDate() != null && data.dischargeReasonId() == null) throw new IllegalArgumentException("Motivo de baixa não pode ser nulo quando existe uma data.");


        animal.setUser(requester);
        animal.setName(data.name());
        animal.setMicrochipNumber(data.microchipNumber());
        animal.setBreed(rfcSvc.getBreed(data.breedId()));
        animal.setColor(rfcSvc.getColor(data.colorId()));
        animal.setGender(data.gender());
        animal.setBirthDate(data.birthDate());
        animal.setIntakeDate(data.intakeDate());
        animal.setDischargeDate(data.dischargeDate());
        animal.setDischargeReason(data.dischargeDate() != null ? rfcSvc.getDischargeReason(data.dischargeReasonId()) : null);
        animal.setToAdoption(data.toAdoption());

        return anmRep.save(animal);
    }


    @Transactional
    public Animal setImage(LoggedUserPayload user, int animalId, @Valid ImageRequest image) {

        User requester = (User) usrSvc.loadUserByUsername(user.email());
        Animal animal = this.getById(animalId);
        String url = imgSvc.uploadImage(image);

        animal.setImgUrl(url);
        animal.setUser(requester);
        return anmRep.save(animal);
    }
}

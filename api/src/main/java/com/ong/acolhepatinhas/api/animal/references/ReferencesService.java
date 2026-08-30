package com.ong.acolhepatinhas.api.animal.references;

import java.util.List;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.animal.AnimalRepository;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewBreedRequest;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalBreedRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalColorRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalDischargeReasonRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalSpecieRepository;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class ReferencesService {
    
    private final AnimalRepository anmRep;

    private final AnimalBreedRepository brdRep;
    private final AnimalColorRepository clrRep;
    private final AnimalDischargeReasonRepository drsRep;
    private final AnimalSpecieRepository spcRep;


    // Getters
    @Cacheable(value = "AnimalColors")
    public List<AnimalColor> listAllColors() {
        return clrRep.findAll();
    }

    @Cacheable(value = "animalDischargeReasons")
    public List<AnimalDischargeReason> listAllDischargeReasons() {
        return drsRep.findAll();
    }

    @Cacheable(value = "animalSpeciesWithBreeds")
    public List<AnimalSpecie> listAllSpeciesWithBreeds() {
        return spcRep.findAllWithBreeds();
    }

    @Cacheable(value = "animalBreeds")
    public List<AnimalBreed> listAllBreeds() {
        return brdRep.findAll();
    }



    // Setters
    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalBreeds", allEntries = true),
        @CacheEvict(value = "animalSpeciesWithBreeds", allEntries = true)
    })
    public AnimalBreed newBreed(@Valid NewBreedRequest data) {

        AnimalSpecie specie = spcRep.findById(data.specieId()).orElseThrow(() -> new ValueNotFoundException("A espécie não existe."));
        if (brdRep.existsByNameAndSpecie(data.name(), specie)) throw new DuplicatedValueException("Raça já cadastrada.");

        AnimalBreed breed = AnimalBreed.builder()
            .specie(specie)
            .name(data.name())
            .build();

        return brdRep.save(breed);
    }

    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalBreeds", allEntries = true),
        @CacheEvict(value = "animalSpeciesWithBreeds", allEntries = true)
    })
    public void deleteBreed(int breedId) {

        AnimalBreed breed = brdRep.findById(breedId).orElseThrow(() -> new ValueNotFoundException("Raça não encontrada."));
        if (anmRep.existsByBreed(breed)) throw new ResourceInUseException("A raça não pôde ser deletada pois está vinculada a um animal.");

        brdRep.delete(breed);
    }
}

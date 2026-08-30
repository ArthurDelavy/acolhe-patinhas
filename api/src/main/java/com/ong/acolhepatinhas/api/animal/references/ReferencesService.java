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
import com.ong.acolhepatinhas.api.animal.references.DTO.NewColorRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewDischargeReasonRequest;
import com.ong.acolhepatinhas.api.animal.references.DTO.NewSpecieRequest;
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
    @Cacheable(value = "animalColors")
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

    @Cacheable(value = "animalSpecies")
    public List<AnimalSpecie> listAllSpecies() {
        return spcRep.findAll();
    }


    @Cacheable(value = "animalColor", key = "#id")
    public AnimalColor getColor(int id) {
        return clrRep.findById(id).orElseThrow(() -> new ValueNotFoundException("Cor não encontrada."));
    }

    @Cacheable(value = "animalBreed", key = "#id")
    public AnimalBreed getBreed(int id) {
        return brdRep.findById(id).orElseThrow(() -> new ValueNotFoundException("Raça não encontrada."));
    }

    @Cacheable(value = "animalDischargeReason", key = "#id")
    public AnimalDischargeReason getDischargeReason(int id) {
        return drsRep.findById(id).orElseThrow(() -> new ValueNotFoundException("Motivo não encontrado."));
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
        @CacheEvict(value = "animalSpecies", allEntries = true),
        @CacheEvict(value = "animalSpeciesWithBreeds", allEntries = true)
    })
    public AnimalSpecie newSpecie(@Valid NewSpecieRequest data) {

        if (spcRep.existsByName(data.name())) throw new DuplicatedValueException("Espécie já cadastrada.");

        AnimalSpecie specie = AnimalSpecie.builder()
            .name(data.name())
            .build();

        return spcRep.save(specie);
    }


    @Transactional
    @CacheEvict(value = "animalColors", allEntries = true)    
    public AnimalColor newColor(@Valid NewColorRequest data) {

        if (clrRep.existsByName(data.name())) throw new DuplicatedValueException("Cor já cadastrada.");

        AnimalColor color = AnimalColor.builder()
            .name(data.name())
            .build();

        return clrRep.save(color);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalDischargeReasons", allEntries = true),
        @CacheEvict(value = "animalDischargeReason", allEntries = true)

    })
    public AnimalDischargeReason newDischargeReason(@Valid NewDischargeReasonRequest data) {

        if (drsRep.existsByName(data.name())) throw new DuplicatedValueException("Motivo já cadastrado.");

        AnimalDischargeReason reason = AnimalDischargeReason.builder()
            .name(data.name())
            .build();

        return drsRep.save(reason);
    }





    // Deletes
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


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalSpecies", allEntries = true),
        @CacheEvict(value = "animalSpeciesWithBreeds", allEntries = true)
    })
    public void deleteSpecie(int specieId) {

        AnimalSpecie specie = spcRep.findById(specieId).orElseThrow(() -> new ValueNotFoundException("Espécie não encontrada."));
        if (anmRep.existsBySpecie(specie)) throw new ResourceInUseException("A espécie não pôde ser deletada pois está vinculada a um animal.");

        spcRep.delete(specie);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalColors", allEntries = true),
        @CacheEvict(value = "animalColor", allEntries = true)
    })
    public void deleteColor(int colorId) {

        AnimalColor color = clrRep.findById(colorId).orElseThrow(() -> new ValueNotFoundException("Cor não encontrada."));
        if (anmRep.existsByColor(color)) throw new ResourceInUseException("A cor não pôde ser deletada pois está vinculada a um animal.");

        clrRep.delete(color);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "animalDischargeReasons", allEntries = true),
        @CacheEvict(value = "animalDischargeReason", allEntries = true)
    })
    public void deleteDischargeReason(int reasonId) {

        AnimalDischargeReason reason = drsRep.findById(reasonId).orElseThrow(() -> new ValueNotFoundException("Motivo não encontrado."));
        if (anmRep.existsByDischargeReason(reason)) throw new ResourceInUseException("O motivo não pôde ser deletado pois está vinculado a um animal.");

        drsRep.delete(reason);
    }
}

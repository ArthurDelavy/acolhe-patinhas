package com.ong.acolhepatinhas.api.veterinary.vaccine.catalog;

import java.util.List;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.DTO.NewVaccineRequest;
import com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination.VaccinationService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor 
@Transactional(readOnly = true)
public class VaccineService {
    
    private final VaccineRepository vccRep;
    
    private final VaccinationService vctSvc;



    @Cacheable(value = "vaccines")
    public List<Vaccine> listAll() {
        return vccRep.findAll();
    }

    @Cacheable(value = "vaccine", key = "#vaccineId")
    public Vaccine getById(int vaccineId) {
        return vccRep.findById(vaccineId).orElseThrow(() -> new ValueNotFoundException("Vacina não encontrada."));
    }


    @Transactional
    @CacheEvict(value = "vaccines", allEntries = true)
    public Vaccine newVaccine(@Valid NewVaccineRequest data) {
        
        if (vccRep.existsByName(data.name())) throw new DuplicatedValueException("Vacina já cadastrada");

        Vaccine vaccine = Vaccine.builder()
            .name(data.name())
            .build();

        return vccRep.save(vaccine);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "vaccines", allEntries = true),
        @CacheEvict(value = "vaccine", key = "#vaccineId")
    })
    public void deleteVaccine(int vaccineId) {

        Vaccine vaccine = getById(vaccineId);
        if (vctSvc.existsByVaccine(vaccine)) throw new ResourceInUseException("A vacina não pôde ser deletada pois está vinculada a um animal.");

        vccRep.delete(vaccine);
    }
}

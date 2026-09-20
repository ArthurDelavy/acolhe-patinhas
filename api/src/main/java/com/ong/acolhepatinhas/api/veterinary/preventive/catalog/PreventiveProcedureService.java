package com.ong.acolhepatinhas.api.veterinary.preventive.catalog;

import java.util.List;

import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO.NewPreventiveProcedureRequest;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service 
@RequiredArgsConstructor
@Validated
@Transactional(readOnly = true)
public class PreventiveProcedureService {
    
    private final PreventiveProcedureRepository pvpRep;

    // private final SurgeryService srgSvc;


    public boolean existsByName(String name) {
        return pvpRep.existsByName(name);
    }

    @Cacheable(value = "prevProcedure", key = "#procedureId")
    public PreventiveProcedure getById(int procedureId) {
        return pvpRep.findById(procedureId).orElseThrow(() -> new ValueNotFoundException("Procedimento não encontrado."));
    }

    @Cacheable(value = "prevProcedures")
    public List<PreventiveProcedure> listAll() {
        return pvpRep.findAll();
    }


    @Transactional
    @CacheEvict(value = "prevProcedures", allEntries = true)
    public PreventiveProcedure newProcedure(@Valid NewPreventiveProcedureRequest data) {

        if (this.existsByName(data.name())) throw new DuplicatedValueException("Procedimento já cadastrado.");

        PreventiveProcedure procedure = PreventiveProcedure.builder()
            .name(data.name())
            .defaultFrequencyDays(data.defaultFrequencyDays())
            .build();

        return pvpRep.save(procedure);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "prevProcedures", allEntries = true),
        @CacheEvict(value = "prevProcedure", key = "#procedureId")
    })
    public void deleteProcedure(int procedureId) {

        PreventiveProcedure procedure = this.getById(procedureId);

        // if (srgSvc.existsBySurgicalProcedure(procedure)) throw new ResourceInUseException("O procedimento não pôde ser deletado pois está vinculado a um cuidado preventivo.");
    
        pvpRep.delete(procedure);
    }
}

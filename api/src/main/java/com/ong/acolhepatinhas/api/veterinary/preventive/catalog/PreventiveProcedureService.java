package com.ong.acolhepatinhas.api.veterinary.preventive.catalog;

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
import com.ong.acolhepatinhas.api.veterinary.preventive.catalog.DTO.NewPreventiveProcedureRequest;
import com.ong.acolhepatinhas.api.veterinary.preventive.procedure.PreventiveCareService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service 
@RequiredArgsConstructor
@Validated
@Transactional(readOnly = true)
public class PreventiveProcedureService {
    
    private final PreventiveProcedureRepository pvpRep;

    @Autowired @Lazy
    private PreventiveCareService pvcSvc;

    private final ApplicationEventPublisher evtPbs;


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

        PreventiveProcedure newProcedure = pvpRep.save(procedure);

        evtPbs.publishEvent(new AuditLogEvent(
            "PREVENTIVE_PROCEDURE_CREATED",
            "Procedure/%d".formatted(newProcedure.getId()),
            null
        ));

        return newProcedure;
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "prevProcedures", allEntries = true),
        @CacheEvict(value = "prevProcedure", key = "#procedureId")
    })
    public void deleteProcedure(int procedureId) {

        PreventiveProcedure procedure = this.getById(procedureId);

        if (pvcSvc.existsByPreventiveProcedure(procedure)) throw new ResourceInUseException("O procedimento não pôde ser deletado pois está vinculado a um cuidado preventivo.");
    
        pvpRep.delete(procedure);

        evtPbs.publishEvent(new AuditLogEvent(
            "PREVENTIVE_PROCEDURE_DELETED",
            "Procedure/%d".formatted(procedure.getId()),
            """
            {
                "deletedRecord": {
                    "name": "%s"
                }
            }
            """.formatted(procedure.getName())
        ));
    }
}

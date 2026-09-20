package com.ong.acolhepatinhas.api.veterinary.surgery.catalog;

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
import com.ong.acolhepatinhas.api.veterinary.surgery.catalog.DTO.NewSurgicalProcedureRequest;
import com.ong.acolhepatinhas.api.veterinary.surgery.procedure.SurgeryService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class SurgicalProcedureService {
    
    private final SurgicalprocedureRepository sgpRep;

    private final SurgeryService srgSvc;


    public boolean existsByName(String name) {
        return sgpRep.existsByName(name);
    }

    @Cacheable(value = "procedure", key = "#procedureId")
    public SurgicalProcedure getById(int procedureId) {
        return sgpRep.findById(procedureId).orElseThrow(() -> new ValueNotFoundException("Procedimento não encontrado."));
    }

    @Cacheable(value = "procedures")
    public List<SurgicalProcedure> listAll() {
        return sgpRep.findAll();
    }


    @Transactional
    @CacheEvict(value = "procedures", allEntries = true)
    public SurgicalProcedure newProcedure(@Valid NewSurgicalProcedureRequest data) {

        if (this.existsByName(data.name())) throw new DuplicatedValueException("Procedimento já cadastrado.");

        SurgicalProcedure procedure = SurgicalProcedure.builder()
            .name(data.name())
            .build();

        return sgpRep.save(procedure);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "procedures", allEntries = true),
        @CacheEvict(value = "procedure", key = "#procedureId")
    })
    public void deleteProcedure(int procedureId) {

        SurgicalProcedure procedure = this.getById(procedureId);

        if (srgSvc.existsBySurgicalProcedure(procedure)) throw new ResourceInUseException("O procedimento não pôde ser deletado pois está vinculado a uma cirurgia.");
    
        sgpRep.delete(procedure);
    }
}

package com.ong.acolhepatinhas.api.veterinary.labtest.catalog;

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
import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.DTO.NewLaboratoryTestRequest;
import com.ong.acolhepatinhas.api.veterinary.labtest.result.LaboratoryTestResultService;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service 
@RequiredArgsConstructor
@Validated
@Transactional(readOnly = true)
public class LaboratoryTestService {
    

    private final LaboratoryTestRepository lbtRep;

    private final LaboratoryTestResultService ltrSvc;


    public boolean existsByName(String name) {
        return lbtRep.existsByName(name);
    }

    @Cacheable(value = "labTest", key = "#labTestId")
    public LaboratoryTest getById(int labTestId) {
        return lbtRep.findById(labTestId).orElseThrow(() -> new ValueNotFoundException("Tipo de teste não encontrado."));
    }

    @Cacheable(value = "labTests")
    public List<LaboratoryTest> listAll() {
        return lbtRep.findAll();
    }


    @Transactional
    @CacheEvict(value = "labTests", allEntries = true)
    public LaboratoryTest newTest(@Valid NewLaboratoryTestRequest data) {

        if (this.existsByName(data.name())) throw new DuplicatedValueException("Tipo de teste já cadastrado.");

        LaboratoryTest test = LaboratoryTest.builder()
            .name(data.name())
            .build();

        return lbtRep.save(test);
    }


    @Transactional
    @Caching(evict = {
        @CacheEvict(value = "labTests", allEntries = true),
        @CacheEvict(value = "labTest", key = "#labTestId")
    })
    public void deleteTest(int labTestId) {

        LaboratoryTest test = this.getById(labTestId);

        if (ltrSvc.existsByLabTest(test)) throw new ResourceInUseException("O tipo de teste não pôde ser deletado pois está vinculado a um resultado.");
    
        lbtRep.delete(test);
    }
}

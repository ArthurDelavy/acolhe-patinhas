package com.ong.acolhepatinhas.api.animal.references;

import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalSpecie;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalBreedRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalColorRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalDischargeReasonRepository;
import com.ong.acolhepatinhas.api.animal.references.repositories.AnimalSpecieRepository;

@Service
@Transactional(readOnly = true)
public class ReferencesService {
    
    @Autowired
    private AnimalBreedRepository brdRep;

    @Autowired
    private AnimalColorRepository clrRep;

    @Autowired
    private AnimalDischargeReasonRepository drsRep;

    @Autowired
    private AnimalSpecieRepository spcRep;



    @Cacheable
    public List<AnimalColor> listAllColors() {
        return clrRep.findAll();
    }

    public List<AnimalDischargeReason> listAllDischargeReasons() {
        return drsRep.findAll();
    }

    public List<AnimalSpecie> listAllSpeciesWithBreeds() {
        return spcRep.findAllWithBreeds();
    }
}

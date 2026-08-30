package com.ong.acolhepatinhas.api.animal;

import java.util.List;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class AnimalService {
    
    private final AnimalRepository anmRep;

    public List<Animal> listAll() {
        return anmRep.findAll();
    }
}

package com.ong.acolhepatinhas.api.fosterhome;

import java.util.List;
import java.util.Objects;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.fosterhome.DTO.NewFosterHomeRequest;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class FosterHomeService {
    
    private final FosterHomeRepository fhmRep;

    private final UserService usrSvc;
    
    private static final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);



    public List<FosterHome> listAll() {
        return fhmRep.findAll();
    }

    public FosterHome getById(int id) {
        return fhmRep.findById(id).orElseThrow(() -> new ValueNotFoundException("Lar não encontrado."));
    }



    @Transactional
    public FosterHome newHome(LoggedUserPayload requester, @Valid NewFosterHomeRequest data) {

        if (fhmRep.existsByName(data.name())) throw new ResourceInUseException("Lar já cadastrado.");
        
        User userRequester = (User) usrSvc.loadUserByUsername(requester.email());
        User userOwner =  (User) usrSvc.loadUserByUsername(data.ownerEmail());

        Point location = geometryFactory.createPoint(new Coordinate(data.longitude(), data.latitude()));

        FosterHome fosterHome = FosterHome.builder()
            .user(userRequester)
            .owner(userOwner)
            .name(data.name())
            .phoneNumber(data.phoneNumber())
            .email(data.email())
            .location(location)
            .capacity(data.capacity())
            .build();

        return fhmRep.save(fosterHome);
    }


    @Transactional
    public FosterHome editHome(LoggedUserPayload requester, int homeId, @Valid NewFosterHomeRequest data) {

        FosterHome fosterHome = this.getById(homeId);

        User userRequester = (User) usrSvc.loadUserByUsername(requester.email());
        User userOwner =  (User) usrSvc.loadUserByUsername(data.ownerEmail());

        Point location = geometryFactory.createPoint(new Coordinate(data.longitude(), data.latitude()));

        if (
            !Objects.equals(fosterHome.getName(), data.name()) &&
            fhmRep.existsByName(data.name())
        ) throw new ResourceInUseException("Lar já cadastrado.");

        fosterHome.setUser(userRequester);
        fosterHome.setOwner(userOwner);
        fosterHome.setName(data.name());
        fosterHome.setPhoneNumber(data.phoneNumber());
        fosterHome.setEmail(data.email());
        fosterHome.setLocation(location);
        fosterHome.setCapacity(data.capacity());

        return fhmRep.save(fosterHome);
    }


    @Transactional
    public void deleteHome(int homeId) {
        FosterHome fosterHome = this.getById(homeId);
        fhmRep.delete(fosterHome);
    }
}

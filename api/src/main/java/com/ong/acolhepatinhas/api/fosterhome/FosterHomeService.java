package com.ong.acolhepatinhas.api.fosterhome;

import java.util.List;
import java.util.Objects;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ResourceInUseException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.fosterhome.DTO.NewFosterHomeRequest;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.utils.ObjectComparator;

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

    private final ApplicationEventPublisher evtPbs;
    private final ObjectComparator objCpr;



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

        FosterHome newHome = fhmRep.save(fosterHome);


        evtPbs.publishEvent(new AuditLogEvent(
            "FOSTER_HOME_CREATED",
            "FosterHome/%d".formatted(newHome.getId()),
            null
        ));

        return newHome;
    }


    @Transactional
    public FosterHome editHome(LoggedUserPayload requester, int homeId, @Valid NewFosterHomeRequest data) {

        FosterHome fosterHome = this.getById(homeId);
        NewFosterHomeRequest oldHome = NewFosterHomeRequest.fromFosterHome(fosterHome);

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

        FosterHome newHome = fhmRep.save(fosterHome);


        evtPbs.publishEvent(new AuditLogEvent(
            "FOSTER_HOME_EDITED",
            "FosterHome/%d".formatted(newHome.getId()),
            objCpr.getDifferentAttributes(oldHome, newHome)
        ));

        return newHome;
    }


    @Transactional
    public void deleteHome(int homeId) {
        FosterHome fosterHome = this.getById(homeId);
        fhmRep.delete(fosterHome);

        evtPbs.publishEvent(new AuditLogEvent(
            "FOSTER_HOME_DELETED",
            "FosterHome/%d".formatted(fosterHome.getId()),
            """
            {
                "deletedRecord": {
                    "name": "%s",
                    "phoneNumber": "%s",
                    "email": "%s"
                }
            }
            """.formatted(fosterHome.getName(), fosterHome.getPhoneNumber(), fosterHome.getEmail())
        ));
    }
}

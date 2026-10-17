package com.ong.acolhepatinhas.api.report;

import java.time.Instant;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.report.DTO.NewReportRequest;
import com.ong.acolhepatinhas.api.report.enums.ReportStatus;
import com.ong.acolhepatinhas.api.services.imageService.ImageService;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
@Validated
@Transactional(readOnly = true)
public class AnimalReportService {
    
    private final AnimalReportRepository arpRep;

    private final UserService usrSvc;
    private final ImageService imgSvc;
    
    private static final GeometryFactory geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);


    @Transactional
    public AnimalReport newReport(LoggedUserPayload requester, @Valid NewReportRequest data) {
        
        User user = null;
        if (!requester.email().endsWith("@anonymous.local"))
            user = (User) usrSvc.loadUserByUsername(requester.email());

        Point location = geometryFactory.createPoint(new Coordinate(data.longitude(), data.latitude()));

        AnimalReport report = AnimalReport.builder()
            .user(user)
            .type(data.type())
            .status(ReportStatus.OPEN)
            .title(data.title())
            .description(data.description())
            .location(location)
            .createdAt(Instant.now())
            .updatedAt(Instant.now())
            .build();

        arpRep.save(report);

        if (data.image() != null) {
            String url = imgSvc.saveImage(
                new ImageRequest(data.image()), String.valueOf(report.getId()), StorageFileType.REPORT_PHOTO);
        
            report.setImageUrl(url);
        }

        return report;
    }
}

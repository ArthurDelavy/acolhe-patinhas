package com.ong.acolhepatinhas.api.report;

import java.time.Instant;
import java.util.List;

import org.locationtech.jts.geom.Coordinate;
import org.locationtech.jts.geom.GeometryFactory;
import org.locationtech.jts.geom.Point;
import org.locationtech.jts.geom.PrecisionModel;
import org.springframework.context.ApplicationEventPublisher;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.report.DTO.NewReportRequest;
import com.ong.acolhepatinhas.api.report.DTO.ReportStatusUpdateRequest;
import com.ong.acolhepatinhas.api.report.enums.ReportStatus;
import com.ong.acolhepatinhas.api.services.imageService.ImageService;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;
import com.ong.acolhepatinhas.api.services.logs.DTO.AuditLogEvent;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.utils.ObjectComparator;

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

    private final ApplicationEventPublisher evtPbs; 
    private final ObjectComparator objCpr;



    public AnimalReport getById(int id) {
        return arpRep.findById(id).orElseThrow(() -> new ValueNotFoundException("Reporte não encontrado"));
    }

    public List<AnimalReport> listAll() {
        return arpRep.findAll();
    }


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
                new ImageRequest(data.image()), "rep" + String.valueOf(report.getId()), StorageFileType.REPORT_PHOTO);
        
            report.setImageUrl(url);
        }


        evtPbs.publishEvent(new AuditLogEvent(
            "REPORT_CREATED",
            "Report/%d".formatted(report.getId()),
            null
        ));

        return report;
    }


    @Transactional
    public AnimalReport updateStatus(int reportId, @Valid ReportStatusUpdateRequest data) {

        AnimalReport report = this.getById(reportId);

        ReportStatusUpdateRequest oldReport = ReportStatusUpdateRequest.fromReport(report);

        report.setStatus(data.status());
        report.setUpdatedAt(Instant.now());

        AnimalReport newReport = arpRep.save(report); 
        
        
        evtPbs.publishEvent(new AuditLogEvent(
            "REPORT_STATUS_UPDATED",
            "Report/%d".formatted(newReport.getId()),
            objCpr.getDifferentAttributes(oldReport, data)
        ));
        
        return newReport;
    }
}

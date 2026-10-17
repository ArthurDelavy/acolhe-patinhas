package com.ong.acolhepatinhas.api.report;


import java.time.Instant;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;
import org.locationtech.jts.geom.Point;

import com.ong.acolhepatinhas.api.report.enums.ReportStatus;
import com.ong.acolhepatinhas.api.report.enums.ReportType;
import com.ong.acolhepatinhas.api.user.User;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.EnumType;
import jakarta.persistence.Enumerated;
import jakarta.persistence.FetchType;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.ManyToOne;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.RequiredArgsConstructor;
import lombok.Setter;



@Entity
@Getter @Setter @Builder
@AllArgsConstructor @RequiredArgsConstructor
@DynamicInsert @DynamicUpdate
@Table(name = "animal_reports")
public class AnimalReport {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id")
    private User user;

    @Enumerated(EnumType.STRING)
    private ReportType type;

    @Enumerated(EnumType.STRING)
    private ReportStatus status;

    private String title;
    private String description;
    private String imageUrl;
    
    @Column(columnDefinition = "geography(Point, 4326)")
    private Point location;

    private Instant createdAt;
    private Instant updatedAt;
}

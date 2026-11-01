package com.ong.acolhepatinhas.api.services.logs;

import java.time.Instant;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Getter
@AllArgsConstructor @NoArgsConstructor @Builder
@Table(name = "audit_logs")
public class AuditLog {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private long id;

    private String actor;
    private String action;
    private String resource;
    private String details;
    private String ip;
    private String agent;
    private Instant timestamp;
}

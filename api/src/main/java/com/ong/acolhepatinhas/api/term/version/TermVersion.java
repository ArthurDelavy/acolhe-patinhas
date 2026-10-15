package com.ong.acolhepatinhas.api.term.version;

import java.time.OffsetDateTime;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter @Setter @Builder
@NoArgsConstructor @AllArgsConstructor
@DynamicInsert @DynamicUpdate
@Table(name = "term_versions")
public class TermVersion {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    private String version;
    private String filePath;
    private String contentHash;
    private OffsetDateTime effectiveAt;
    private boolean isCurrent; 
}

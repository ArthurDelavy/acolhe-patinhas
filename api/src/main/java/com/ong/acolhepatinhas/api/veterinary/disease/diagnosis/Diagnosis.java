package com.ong.acolhepatinhas.api.veterinary.disease.diagnosis;

import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.ong.acolhepatinhas.api.veterinary.disease.catalog.Disease;
import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.enums.DiseaseStatus;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;

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
import lombok.NoArgsConstructor;
import lombok.Setter;

@Entity
@Getter @Setter 
@NoArgsConstructor @AllArgsConstructor @Builder
@DynamicInsert @DynamicUpdate
@Table(name = "diagnoses")
public class Diagnosis {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "Veterinary_record_id")
    private VeterinaryRecord vetRecord;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "disease_id")
    private Disease disease;

    private LocalDate diagnosedAt;

    @Enumerated(EnumType.STRING) @JdbcTypeCode(SqlTypes.ENUM)
    private DiseaseStatus status;
}

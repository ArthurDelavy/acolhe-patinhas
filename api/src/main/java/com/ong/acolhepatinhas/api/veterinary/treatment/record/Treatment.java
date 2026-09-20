package com.ong.acolhepatinhas.api.veterinary.treatment.record;

import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.ong.acolhepatinhas.api.veterinary.disease.diagnosis.Diagnosis;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.enums.TreatmentStatus;

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
@Getter @Setter @Builder
@AllArgsConstructor @NoArgsConstructor
@DynamicInsert @DynamicUpdate
@Table(name = "treatments")
public class Treatment {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "veterinary_record_id")
    VeterinaryRecord vetRecord;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "diagnosis_id", nullable = true)
    Diagnosis diagnosis;

    LocalDate startDate;
    LocalDate endDate;

    @Enumerated(EnumType.STRING) @JdbcTypeCode(SqlTypes.ENUM)
    TreatmentStatus status;

    String observations;
}

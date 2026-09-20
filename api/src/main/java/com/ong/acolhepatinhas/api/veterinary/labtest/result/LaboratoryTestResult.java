package com.ong.acolhepatinhas.api.veterinary.labtest.result;

import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import com.ong.acolhepatinhas.api.veterinary.labtest.catalog.LaboratoryTest;
import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;

import jakarta.persistence.Entity;
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
@NoArgsConstructor @AllArgsConstructor
@DynamicInsert @DynamicUpdate
@Table(name = "lab_test_results")
public class LaboratoryTestResult {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "veterinary_record_id")
    private VeterinaryRecord vetRecord;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "lab_test_id")
    private LaboratoryTest labTest;

    private LocalDate testDate;

    private String results;
    private String observations;
}

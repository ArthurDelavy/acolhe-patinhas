package com.ong.acolhepatinhas.api.veterinary.vaccine.vaccination;

import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import com.ong.acolhepatinhas.api.veterinary.record.VeterinaryRecord;
import com.ong.acolhepatinhas.api.veterinary.vaccine.catalog.Vaccine;

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
@Table(name = "vaccinations")
public class Vaccination {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "veterinary_record_id")
    private VeterinaryRecord vetRecord;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "vaccine_id")
    private Vaccine vaccine;

    private String dose;
    private String manufacturer;
    private String batchNumber;

    private LocalDate vaccinationDate;
    private LocalDate nextDoseDate;
}

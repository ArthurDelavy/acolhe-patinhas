package com.ong.acolhepatinhas.api.veterinary.treatment.posology;

import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import com.ong.acolhepatinhas.api.veterinary.medicine.Medicine;
import com.ong.acolhepatinhas.api.veterinary.treatment.record.Treatment;

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
@Table(name = "treatment_medicines")
public class TreatmentMedicine {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "treatment_id")
    Treatment treatment;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "medicine_id")
    Medicine medicine;

    String dosage;
    String frequency;

    int durationDays;
    LocalDate startDate;
}

package com.ong.acolhepatinhas.api.animal;

import java.time.LocalDate;
import java.time.OffsetDateTime;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import com.ong.acolhepatinhas.api.animal.enums.Genders;
import com.ong.acolhepatinhas.api.animal.reference.entities.Breed;
import com.ong.acolhepatinhas.api.animal.reference.entities.Color;
import com.ong.acolhepatinhas.api.animal.reference.entities.DischargeReason;
import com.ong.acolhepatinhas.api.user.User;

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
@AllArgsConstructor @NoArgsConstructor @Builder
@DynamicInsert @DynamicUpdate
@Table(name = "animals")
public class Animal {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "user_id")
    private User user;

    private String name;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "breeds_id")
    private Breed breed;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "colors_id")
    private Color color;

    @Enumerated(EnumType.STRING)
    private Genders gender;

    private LocalDate birthDate;
    private OffsetDateTime intakeDate;
    private OffsetDateTime dischargeDate;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "discharge_reasons.id")
    private DischargeReason dischargeReason;

    private boolean toAdoption;

    private String microchipNumber;
}

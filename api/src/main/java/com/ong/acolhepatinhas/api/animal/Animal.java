package com.ong.acolhepatinhas.api.animal;

import java.time.Instant;
import java.time.LocalDate;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import com.ong.acolhepatinhas.api.animal.enums.Gender;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalBreed;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalColor;
import com.ong.acolhepatinhas.api.animal.references.entities.AnimalDischargeReason;
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
    
    private String microchipNumber;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "breed_id")
    private AnimalBreed breed;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "color_id")
    private AnimalColor color;

    @Enumerated(EnumType.STRING) @JdbcTypeCode(SqlTypes.NAMED_ENUM)
    private Gender gender;

    private LocalDate birthDate;
    private Instant intakeDate;
    private Instant dischargeDate;

    @ManyToOne(fetch = FetchType.LAZY) @JoinColumn(name = "discharge_reason_id")
    private AnimalDischargeReason dischargeReason;

    private boolean toAdoption;

    private String imageUrl;
}

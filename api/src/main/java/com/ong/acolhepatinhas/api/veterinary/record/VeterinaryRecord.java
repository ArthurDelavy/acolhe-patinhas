package com.ong.acolhepatinhas.api.veterinary.record;

import org.hibernate.annotations.DynamicInsert;
import org.hibernate.annotations.DynamicUpdate;

import com.ong.acolhepatinhas.api.animal.Animal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.FetchType;
import jakarta.persistence.Id;
import jakarta.persistence.JoinColumn;
import jakarta.persistence.MapsId;
import jakarta.persistence.OneToOne;
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
@Table(name = "veterinary_records")
public class VeterinaryRecord {
    
    @Id
    private int id;

    @OneToOne(fetch = FetchType.LAZY) @MapsId @JoinColumn(name = "animal_id")
    private Animal animal;

    @Column(name = "size_cm")
    private Integer size; // Tamanho definido em cm

    private Double weight; // Peso em kg

    private boolean neutered;
}

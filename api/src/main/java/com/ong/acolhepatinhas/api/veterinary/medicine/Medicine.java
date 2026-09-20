package com.ong.acolhepatinhas.api.veterinary.medicine;

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
@DynamicInsert @DynamicUpdate
@AllArgsConstructor @NoArgsConstructor
@Table(name = "medicines")
public class Medicine {
    
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private int id;

    private String name;
}

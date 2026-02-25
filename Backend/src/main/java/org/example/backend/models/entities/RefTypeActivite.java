package org.example.backend.models.entities;

import jakarta.persistence.*;
import lombok.Data;
import lombok.Getter;
import lombok.Setter;
import lombok.ToString;

@Getter
@Setter
@Data
@Entity
@Table(name = "ref_type_activite")
@ToString
public class RefTypeActivite {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "id", nullable = false)
    private Integer id;

    @Column(name = "libelle", nullable = false, length = Integer.MAX_VALUE)
    private String libelle;

    @Override
    public String toString() {
        return "RefTypeActivite{" +
                "id=" + id +
                ", libelle='" + libelle + '\'' +
                '}';
    }
}
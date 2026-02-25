package org.example.backend.repositories;

import org.example.backend.models.entities.Parcelle;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository

public interface ParcelleRepository extends JpaRepository<Parcelle, Integer> {
}
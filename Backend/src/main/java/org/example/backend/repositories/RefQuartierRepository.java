package org.example.backend.repositories;

import org.example.backend.models.entities.RefQuartier;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository

public interface RefQuartierRepository extends JpaRepository<RefQuartier, Integer> {
}
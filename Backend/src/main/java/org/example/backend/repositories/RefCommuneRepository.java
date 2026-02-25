package org.example.backend.repositories;

import org.example.backend.models.entities.RefCommune;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository

public interface RefCommuneRepository extends JpaRepository<RefCommune, Integer> {
}
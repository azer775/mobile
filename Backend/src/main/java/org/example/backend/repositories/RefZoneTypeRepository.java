package org.example.backend.repositories;

import org.example.backend.models.entities.RefZoneType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RefZoneTypeRepository extends JpaRepository<RefZoneType, Integer> {
}
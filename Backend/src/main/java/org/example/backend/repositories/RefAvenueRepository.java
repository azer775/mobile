package org.example.backend.repositories;

import org.example.backend.models.entities.RefAvenue;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository

public interface RefAvenueRepository extends JpaRepository<RefAvenue, Integer> {
}
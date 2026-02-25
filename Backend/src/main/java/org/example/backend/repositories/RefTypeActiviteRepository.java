package org.example.backend.repositories;

import org.example.backend.models.entities.RefTypeActivite;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface RefTypeActiviteRepository extends JpaRepository<RefTypeActivite, Integer> {

}
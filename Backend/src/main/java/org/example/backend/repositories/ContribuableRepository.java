package org.example.backend.repositories;

import org.example.backend.models.entities.Contribuable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ContribuableRepository extends JpaRepository<Contribuable, Integer> {
    Optional<Contribuable> findFirstByPieceIdentite(String pieceIdentite);
    Optional<Contribuable> findFirstByNomRaisonSociale(String nomRaisonSociale);
}

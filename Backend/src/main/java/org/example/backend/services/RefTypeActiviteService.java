package org.example.backend.services;

import org.example.backend.repositories.RefTypeActiviteRepository;
import org.example.backend.models.entities.RefTypeActivite;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RefTypeActiviteService {
    @Autowired
    RefTypeActiviteRepository refTypeActiviteRepository;

    public List<RefTypeActivite> getAllRefTypeActivite() {
        System.out.println(this.refTypeActiviteRepository.findAll());
        return this.refTypeActiviteRepository.findAll();
    }
}

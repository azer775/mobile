package org.example.backend.services;

import org.example.backend.models.dtos.Refs;
import org.example.backend.repositories.*;
import org.example.backend.models.entities.RefTypeActivite;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class RefTypesService {
    @Autowired
    RefTypeActiviteRepository refTypeActiviteRepository;
    @Autowired
    RefZoneTypeRepository refZoneTypeRepository;
    @Autowired
    RefAvenueRepository refAvenueRepository;
    @Autowired
    RefCommuneRepository refCommuneRepository;
    @Autowired
    RefQuartierRepository refQuartierRepository;

    public List<RefTypeActivite> getAllRefTypeActivite() {
        System.out.println(this.refTypeActiviteRepository.findAll());
        return this.refTypeActiviteRepository.findAll();
    }
    public Refs getAllRefs() {
        Refs refs = new Refs();
        refs.setTypeActivites(this.refTypeActiviteRepository.findAll());
        refs.setZoneTypes(this.refZoneTypeRepository.findAll());
        refs.setAvenues(this.refAvenueRepository.findAll());
        refs.setCommunes(this.refCommuneRepository.findAll());
        refs.setQuartiers(this.refQuartierRepository.findAll());
        return refs;
    }
}

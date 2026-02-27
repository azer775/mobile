package org.example.backend.controllers;

import org.example.backend.models.dtos.Refs;
import org.example.backend.models.entities.RefTypeActivite;
import org.example.backend.services.RefTypesService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/reftypes")
public class RefTypesController {
    @Autowired
    RefTypesService refTypesService;
     @GetMapping("/all")
     public Refs getAllRefTypeActivite() {
        return this.refTypesService.getAllRefs();
    }
}

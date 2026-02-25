package org.example.backend.controllers;

import org.example.backend.models.entities.RefTypeActivite;
import org.example.backend.services.RefTypeActiviteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/refTypeActivite")
public class RefTypeActiviteController {
    @Autowired
    RefTypeActiviteService refTypeActiviteService;
     @GetMapping("/all")
     public List<RefTypeActivite> getAllRefTypeActivite() {
        return this.refTypeActiviteService.getAllRefTypeActivite();
    }
}

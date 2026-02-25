package org.example.backend.models.dtos;

import lombok.Data;
import org.example.backend.models.entities.*;

import java.util.List;

@Data
public class Refs {
    List<RefZoneType> zoneTypes;
    List<RefAvenue> avenues;
    List<RefQuartier> quartiers;
    List<RefCommune> communes;
    List<RefTypeActivite> typeActivites;
}

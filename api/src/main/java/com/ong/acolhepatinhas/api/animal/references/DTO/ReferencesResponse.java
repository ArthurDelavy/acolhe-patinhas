package com.ong.acolhepatinhas.api.animal.references.DTO;

import java.util.List;

public record ReferencesResponse(

    List<ColorResponse> colors,
    List<DischargeReasonResponse> dischargeReasons,
    List<SpecieResponse> species,
    List<BreedResponse> breeds
    
) {
}

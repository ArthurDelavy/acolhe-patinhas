package com.ong.acolhepatinhas.api.animal.references;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.animal.references.DTO.ReferencesResponseDTO;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;

@RestController
@RequestMapping("/animal/references")
public class ReferencesController {

    @Autowired
    ReferencesService rfcSvc;

    @GetMapping @PreAuthorize("hasAuthority('animal:read')")
    @Operation(summary = "Todos detalhes listáveis dos animais")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
    public ResponseEntity<ReferencesResponseDTO> listAll() {
       
        ReferencesResponseDTO data = new ReferencesResponseDTO(
            rfcSvc.listAllColors(),
            rfcSvc.listAllDischargeReasons(),
            rfcSvc.listAllSpeciesWithBreeds()
        );

        return ResponseEntity.status(HttpStatus.OK).body(data);
    }

}

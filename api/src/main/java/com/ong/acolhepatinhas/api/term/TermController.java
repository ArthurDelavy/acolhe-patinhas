package com.ong.acolhepatinhas.api.term;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.term.DTO.CurrentTermResponse;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/term")
@Tag(name = "Termos", description = "Termos de Uso e Privacidade")
public class TermController {
    
    private final TermService trmSvc;

    @GetMapping
    @Operation(summary = "Obtém o link de acesso aos termos atualizados")
        @ApiResponse(responseCode = "200", description = "Listado com sucesso!")
        @ApiResponse(responseCode = "500", description = "Nenhum termo encontrado")
    public ResponseEntity<CurrentTermResponse> getTerm() {
        CurrentTermResponse responseData = new CurrentTermResponse(trmSvc.getCurrentTermURL());

        return ResponseEntity.status(HttpStatus.OK).body(responseData);
    }
}

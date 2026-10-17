package com.ong.acolhepatinhas.api.report;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.ong.acolhepatinhas.api.report.DTO.NewReportRequest;
import com.ong.acolhepatinhas.api.report.DTO.ReportResponse;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;

@RestController
@RequiredArgsConstructor
@RequestMapping("/report")
@Tag(name = "Reporte de Animais", description = "Controle de reporte de animais")
public class AnimalReportController {
    
    private final AnimalReportService arpSvc;



    @PostMapping @PreAuthorize("hasAuthority('report:create')")
    @Operation(summary = "Inserir novo lar temporário")
        @SecurityRequirement(name = "BearerToken")
        @ApiResponse(responseCode = "201", description = "Criado com sucesso!")
        @ApiResponse(responseCode = "400", description = "Um ou mais campos estão com valores inválidos", content = @Content)
        @ApiResponse(responseCode = "401", description = "Token ausente ou inválido", content = @Content)
        @ApiResponse(responseCode = "403", description = "Usuário sem permissão para executar a ação", content = @Content)
        @ApiResponse(responseCode = "404", description = "Referência não encontrada", content = @Content)
    public ResponseEntity<ReportResponse> newReport(@AuthenticationPrincipal LoggedUserPayload requester, @RequestBody @Valid NewReportRequest data) {
        ReportResponse responseData = new ReportResponse(arpSvc.newReport(requester, data));
        return ResponseEntity.status(HttpStatus.CREATED).body(responseData);
    }
}

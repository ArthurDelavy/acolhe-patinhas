package com.ong.acolhepatinhas.api.report.DTO;

import com.ong.acolhepatinhas.api.report.enums.ReportStatus;

import jakarta.validation.constraints.NotBlank;

public record ReportStatusUpdateRequest(

    @NotBlank
    ReportStatus status
) {
}

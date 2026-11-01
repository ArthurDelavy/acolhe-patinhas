package com.ong.acolhepatinhas.api.report.DTO;

import com.ong.acolhepatinhas.api.report.AnimalReport;
import com.ong.acolhepatinhas.api.report.enums.ReportStatus;

import jakarta.validation.constraints.NotNull;

public record ReportStatusUpdateRequest(

    @NotNull
    ReportStatus status
) {


    public static ReportStatusUpdateRequest fromReport(AnimalReport data) {
        return new ReportStatusUpdateRequest(data.getStatus());
    }
}

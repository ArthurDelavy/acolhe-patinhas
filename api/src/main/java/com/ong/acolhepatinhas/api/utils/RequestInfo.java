package com.ong.acolhepatinhas.api.utils;

import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import jakarta.servlet.http.HttpServletRequest;

public class RequestInfo {
    
    private RequestInfo() {}

    public static String getClientIp() {

        HttpServletRequest request = getCurrentRequest();
        if (request == null) return "UNKNOWN";

        String xForwardedFor = request.getHeader("X-Forwarded-For");
        if (xForwardedFor != null && !xForwardedFor.isBlank()) return xForwardedFor.split(",")[0].trim();

        return request.getRemoteAddr();
    }


    public static String getUserAgent() {
        
        HttpServletRequest request = getCurrentRequest();
        if (request == null) return "UNKNOWN";

        String userAgent = request.getHeader("User-Agent");
        return userAgent != null ? userAgent : "UNKNOWN";
    }





    private static HttpServletRequest getCurrentRequest() {
        ServletRequestAttributes attributes =
            (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();

        return attributes != null ? attributes.getRequest() : null;
    }
}

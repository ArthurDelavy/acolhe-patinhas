package com.ong.acolhepatinhas.api.exceptions;

import java.time.OffsetDateTime;
import java.util.HashMap;
import java.util.Map;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.authentication.DisabledException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ExpiredDataException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;

@RestControllerAdvice
public class GlobalExceptionHandler {
    
    // Valor inválido nos DTOs
    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorResponse> handleValidationErrors(MethodArgumentNotValidException e) {

        Map<String, String> errors = new HashMap<>();
        for (FieldError fieldError : e.getBindingResult().getFieldErrors()) {
            errors.put(fieldError.getField(), fieldError.getDefaultMessage());
        }

        ErrorResponse error = new ErrorResponse(
            HttpStatus.BAD_REQUEST.value(),
            "Um ou mais campos estão com valores inválidos",
            OffsetDateTime.now(),
            errors
        );

        return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
    }

    
    @ExceptionHandler(BadCredentialsException.class)
    public ResponseEntity<ErrorResponse> handleBadCredentials(BadCredentialsException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.UNAUTHORIZED.value(),
            e.getMessage(),
            OffsetDateTime.now()
        );
        
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }

    @ExceptionHandler(DisabledException.class)
    public ResponseEntity<ErrorResponse> handleDisabledAccount(DisabledException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.FORBIDDEN.value(),
            "E-mail não verificado. Verifique seu e-mail antes de fazer login.",
            OffsetDateTime.now()
        );

        return ResponseEntity.status(HttpStatus.FORBIDDEN).body(error);
    }


    @ExceptionHandler(UsernameNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleUsernameNotFound(UsernameNotFoundException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(),
            e.getMessage(),
            OffsetDateTime.now()
        );
        
        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }
    


    @ExceptionHandler(DuplicatedValueException.class)
    public ResponseEntity<ErrorResponse> handleDuplicatedValue(DuplicatedValueException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.CONFLICT.value(),
            e.getMessage(),
            OffsetDateTime.now()
        );

        return ResponseEntity.status(HttpStatus.CONFLICT).body(error);
    }

    
    @ExceptionHandler(ValueNotFoundException.class)
    public ResponseEntity<ErrorResponse> handleValueNotFound(ValueNotFoundException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.NOT_FOUND.value(), 
            e.getMessage(), 
            OffsetDateTime.now()
        );

        return ResponseEntity.status(HttpStatus.NOT_FOUND).body(error);
    }


    @ExceptionHandler(ExpiredDataException.class)
    public ResponseEntity<ErrorResponse> handleExpiredData(ExpiredDataException e) {
        ErrorResponse error = new ErrorResponse(
            HttpStatus.UNAUTHORIZED.value(),
            e.getMessage(),
            OffsetDateTime.now()
        );

        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
    }
}

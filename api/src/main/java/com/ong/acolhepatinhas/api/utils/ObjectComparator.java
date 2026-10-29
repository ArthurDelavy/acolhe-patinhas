package com.ong.acolhepatinhas.api.utils;

import java.lang.reflect.Field;
import java.util.HashMap;
import java.util.Map;
import java.util.Objects;

import org.springframework.stereotype.Service;

import com.fasterxml.jackson.databind.ObjectMapper;

import lombok.RequiredArgsConstructor;

@Service
@RequiredArgsConstructor
public class ObjectComparator {

    private final ObjectMapper objectMapper = new ObjectMapper();

    public <T> String getDifferentAttributes(T oldObject, T newObject) {
        if (oldObject == null || newObject == null) {
            return null;
        }

        Map<String, Map<String, Object>> changes = new HashMap<>();


        Field[] fields = oldObject.getClass().getDeclaredFields();

        for (Field field : fields) {
            field.setAccessible(true);
            try {
                Object oldValue = field.get(oldObject);
                Object newValue = field.get(newObject);

                
                if (!Objects.equals(oldValue, newValue)) {
                    Map<String, Object> valueDiff = new HashMap<>();
                    valueDiff.put("old", oldValue);
                    valueDiff.put("new", newValue);

                    changes.put(field.getName(), valueDiff);
                }
            } catch (IllegalAccessException e) {}
        }

        
        if (changes.isEmpty()) {
            return null;
        }

        
        try {
            return objectMapper.writeValueAsString(Map.of("changes", changes));
        } catch (Exception e) {
            throw new RuntimeException("Erro ao converter para JSON", e);
        }
    }
}
package com.ong.acolhepatinhas.api.refreshtoken;

import java.time.Instant;
import java.util.List;
import java.util.UUID;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.auth.DTO.RefreshSessionRequest;
import com.ong.acolhepatinhas.api.exceptions.custom.ExpiredDataException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.user.User;

import jakarta.validation.Valid;

@Service
@Transactional(readOnly = true)
@Validated
public class RefreshTokenService {
    
    @Value("${app.refreshTokenExpirationMs}")
    private Long EXPIRATION_TIME;

    @Value("${app.maxUserSessions}")
    private int MAX_SESSIONS;

    @Autowired
    private RefreshTokenRepository rftRep;


    @Transactional
    public UUID newToken(User user) {
        rftRep.deleteByUserAndExpiresAtBefore(user, Instant.now());

        List<RefreshToken> userTokens = rftRep.findAllByUserOrderByExpiresAtAsc(user);
        if (userTokens.size() >= MAX_SESSIONS) rftRep.delete(userTokens.get(0));
        
        RefreshToken token = RefreshToken.builder()
            .user(user)
            .code(UUID.randomUUID())
            .expiresAt(Instant.now().plusMillis(EXPIRATION_TIME))
            .build();

        return rftRep.save(token).getCode();
    }

    @Transactional
    public RefreshToken refreshToken(@Valid RefreshSessionRequest data) {

        RefreshToken currentToken = rftRep.findByCode(data.refreshToken()).orElseThrow(() -> new ValueNotFoundException("Token inválido."));

        if (currentToken.getExpiresAt().isBefore(Instant.now())) {
            rftRep.delete(currentToken);
            throw new ExpiredDataException("Token expirado");
        }
        

        RefreshToken newToken = RefreshToken.builder()
            .user(currentToken.getUser())
            .code(UUID.randomUUID())
            .expiresAt(Instant.now().plusMillis(EXPIRATION_TIME))
            .build();

        rftRep.delete(currentToken);
        
        return rftRep.save(newToken);
    }
}

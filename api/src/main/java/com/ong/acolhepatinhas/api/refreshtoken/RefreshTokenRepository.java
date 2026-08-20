package com.ong.acolhepatinhas.api.refreshtoken;

import java.time.Instant;
import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.user.User;

@Repository
public interface RefreshTokenRepository extends JpaRepository<RefreshToken, Long> {
    Optional<RefreshToken> findByCode(String code);

    List<RefreshToken> findAllByUserOrderByExpiresAtAsc(User user);

    void deleteByUserAndExpiresAtBefore(User user, Instant now);
}

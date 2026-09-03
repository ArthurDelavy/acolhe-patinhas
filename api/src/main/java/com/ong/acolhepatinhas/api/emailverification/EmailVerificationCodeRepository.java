package com.ong.acolhepatinhas.api.emailverification;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.user.User;


@Repository
public interface EmailVerificationCodeRepository extends JpaRepository<EmailVerificationCode, Integer> {
    Optional<EmailVerificationCode> findByUser(User user);
}

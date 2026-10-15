package com.ong.acolhepatinhas.api.emailchange;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.user.User;


@Repository
public interface EmailChangeCodeRepository extends JpaRepository<EmailChangeCode, Integer> {
    Optional<EmailChangeCode> findByUser(User user);
}

package com.ong.acolhepatinhas.api.passwordcode;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.ong.acolhepatinhas.api.user.User;


@Repository
public interface PasswordChangeCodeRepository extends JpaRepository<PasswordChangeCode, Integer> {
    Optional<PasswordChangeCode> findByUser(User user);
}

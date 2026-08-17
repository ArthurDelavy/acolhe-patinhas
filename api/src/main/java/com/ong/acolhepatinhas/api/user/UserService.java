package com.ong.acolhepatinhas.api.user;

import java.time.OffsetDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.auth.DTO.ForgotPasswordRequest;
import com.ong.acolhepatinhas.api.auth.DTO.PasswordChangeRequest;
import com.ong.acolhepatinhas.api.auth.DTO.RegisterRequest;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCodeService;
import com.ong.acolhepatinhas.api.services.EmailService;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

import jakarta.validation.Valid;


@Service
@Transactional(readOnly = true)
@Validated
public class UserService implements UserDetailsService {
    
    @Autowired
    private UserRepository usrRep;

    @Autowired
    private PasswordEncoder pswEcd;

    @Autowired
    private PasswordChangeCodeService pswSvc;

    @Autowired
    private EmailService emlSvc;

    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return usrRep.findByEmail(username).orElseThrow(() -> new UsernameNotFoundException("Usuário não cadastrado."));
    }


    @Transactional
    public UserResponse newUser(@Valid RegisterRequest data) {
        if (usrRep.existsByEmail(data.email())) throw new DuplicatedValueException("E-mail já cadastrado.");

        User user = User.builder()
            .name(data.name())
            .email(data.email())
            .password(pswEcd.encode(data.password()))
            .createdAt(OffsetDateTime.now())
            .build();

        user = usrRep.save(user);

        return UserResponse.from(user);
    }

    @Transactional
    public void changePassword(LoggedUserPayload requester, @Valid PasswordChangeRequest data) {
        
        User user = usrRep.findByEmail(requester.email()).orElseThrow(() -> new UsernameNotFoundException("Usuário não cadastrado"));

        if (!pswEcd.matches(data.oldPassword(), user.getPassword())) throw new BadCredentialsException("Senha incorreta.");
        if (pswEcd.matches(data.newPassword(), user.getPassword())) throw new DuplicatedValueException("A nova senha não pode ser igual à antiga");

        user.setPassword(pswEcd.encode(data.newPassword()));
    }


    public void passwordTokenProcess(@Valid ForgotPasswordRequest data) {

        usrRep.findByEmail(data.email()).ifPresent(user -> {
            String code = pswSvc.newCode(user);
            emlSvc.resetPasswordEmail(user.getEmail(), code);
        });
    }
}

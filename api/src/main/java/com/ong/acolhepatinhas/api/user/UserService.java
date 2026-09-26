package com.ong.acolhepatinhas.api.user;

import java.time.OffsetDateTime;
import java.util.List;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.auth.DTO.ForgotPasswordChangeRequest;
import com.ong.acolhepatinhas.api.auth.DTO.ForgotPasswordRequest;
import com.ong.acolhepatinhas.api.auth.DTO.PasswordChangeRequest;
import com.ong.acolhepatinhas.api.auth.DTO.RegisterRequest;
import com.ong.acolhepatinhas.api.auth.DTO.ResendVerificationRequest;
import com.ong.acolhepatinhas.api.auth.DTO.VerifyEmailRequest;
import com.ong.acolhepatinhas.api.emailverification.EmailVerificationCode;
import com.ong.acolhepatinhas.api.emailverification.EmailVerificationCodeService;
import com.ong.acolhepatinhas.api.exceptions.custom.BusinessRuleException;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCode;
import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCodeService;
import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.services.emailService.EmailService;
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

    @Autowired
    private EmailVerificationCodeService evcSvc;

    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return usrRep.findByEmail(username).orElseThrow(() -> new UsernameNotFoundException("Usuário não cadastrado."));
    }


    public User getById(int userId) {
        return usrRep.findById(userId).orElseThrow(() -> new ValueNotFoundException("Usuário não encontrado."));
    }


    public List<User> listAll() {
        return usrRep.findAll();
    }


    @Transactional
    public UserResponse newUser(@Valid RegisterRequest data) {
        if (usrRep.existsByEmail(data.email())) throw new DuplicatedValueException("E-mail já cadastrado.");

        User user = User.builder()
            .name(data.name())
            .email(data.email())
            .password(pswEcd.encode(data.password()))
            .role(Role.USER)
            .createdAt(OffsetDateTime.now())
            .emailVerified(false)
            .build();

        user = usrRep.save(user);

        String code = evcSvc.newCode(user);
        emlSvc.verificationEmail(user.getEmail(), code);

        return UserResponse.from(user);
    }

    @Transactional
    public void changePassword(LoggedUserPayload requester, @Valid PasswordChangeRequest data) {
        
        User user = usrRep.findByEmail(requester.email()).orElseThrow(() -> new UsernameNotFoundException("Usuário não cadastrado."));

        if (!pswEcd.matches(data.oldPassword(), user.getPassword())) throw new BadCredentialsException("Senha incorreta.");
        if (pswEcd.matches(data.newPassword(), user.getPassword())) throw new DuplicatedValueException("A nova senha não pode ser igual à antiga.");

        user.setPassword(pswEcd.encode(data.newPassword()));
    }

    @Transactional
    public void passwordTokenProcess(@Valid ForgotPasswordRequest data) {

        usrRep.findByEmail(data.email()).ifPresent(user -> {
            String code = pswSvc.newCode(user);
            emlSvc.resetPasswordEmail(user.getName(), user.getEmail(), code);
        });
    }

    @Transactional
    public void resetPassword(@Valid ForgotPasswordChangeRequest data) {
        User user = usrRep.findByEmail(data.email()).orElseThrow(() -> new ValueNotFoundException("Usuário não cadastrado."));
        PasswordChangeCode code = pswSvc.getByUser(user);

        if (!pswEcd.matches(data.passwordChangeToken(), code.getCode())) throw new BadCredentialsException("Código inválido.");
        if (pswEcd.matches(data.newPassword(), user.getPassword())) throw new DuplicatedValueException("A nova senha não pode ser igual à antiga.");

        user.setPassword(pswEcd.encode(data.newPassword()));
        pswSvc.deleteCode(code);
    }

    @Transactional
    public void resendVerificationEmail(@Valid ResendVerificationRequest data) {

        usrRep.findByEmail(data.email()).ifPresent(user -> {
            if (!user.isEmailVerified()) {
                String code = evcSvc.newCode(user);
                emlSvc.verificationEmail(user.getEmail(), code);
            }
        });
    }

    @Transactional
    public User verifyEmail(@Valid VerifyEmailRequest data) {
        User user = usrRep.findByEmail(data.email()).orElseThrow(() -> new ValueNotFoundException("Usuário não cadastrado."));

        if (user.isEmailVerified()) throw new DuplicatedValueException("E-mail já verificado.");

        EmailVerificationCode code = evcSvc.getByUser(user);

        if (!pswEcd.matches(data.code(), code.getCode())) throw new BadCredentialsException("Código inválido.");

        user.setEmailVerified(true);
        evcSvc.deleteCode(code);

        return user;
    }

    @Transactional
    public void toggleUserVerification(int userId) {
        
        User user = this.getById(userId);

        switch (user.getRole()) {
            case ADMIN -> throw new BusinessRuleException("ADMINs não podem ser verificados.");
            case USER -> user.setRole(Role.VERIFIED);
            case VERIFIED -> user.setRole(Role.USER);
        }
    }
}

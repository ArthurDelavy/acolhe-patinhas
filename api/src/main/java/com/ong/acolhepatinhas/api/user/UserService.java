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
import com.ong.acolhepatinhas.api.emailchange.EmailChangeCode;
import com.ong.acolhepatinhas.api.emailchange.EmailChangeCodeService;
import com.ong.acolhepatinhas.api.emailverification.EmailVerificationCode;
import com.ong.acolhepatinhas.api.emailverification.EmailVerificationCodeService;
import com.ong.acolhepatinhas.api.exceptions.custom.BusinessRuleException;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCode;
import com.ong.acolhepatinhas.api.passwordcode.PasswordChangeCodeService;
import com.ong.acolhepatinhas.api.security.enums.Role;
import com.ong.acolhepatinhas.api.services.emailService.EmailService;
import com.ong.acolhepatinhas.api.term.TermService;
import com.ong.acolhepatinhas.api.services.imageService.DTO.ImageRequest;
import com.ong.acolhepatinhas.api.services.imageService.ImageService;
import com.ong.acolhepatinhas.api.services.imageService.enums.StorageFileType;
import com.ong.acolhepatinhas.api.user.DTO.ChangeEmailRequest;
import com.ong.acolhepatinhas.api.user.DTO.ConfirmEmailChangeRequest;
import com.ong.acolhepatinhas.api.user.DTO.EditDescriptionRequest;
import com.ong.acolhepatinhas.api.user.DTO.EditNameRequest;
import com.ong.acolhepatinhas.api.user.DTO.LoggedUserPayload;
import com.ong.acolhepatinhas.api.user.DTO.ProfileResponse;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;

import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;


@Service
@RequiredArgsConstructor 
@Transactional(readOnly = true)
@Validated
public class UserService implements UserDetailsService {
    
    private final UserRepository usrRep;

    private final PasswordEncoder pswEcd;

    private final PasswordChangeCodeService pswSvc;
    private final EmailService emlSvc;
    private final EmailVerificationCodeService evcSvc;
    private final TermService trmSvc;
    private final EmailChangeCodeService eccSvc;
    private final ImageService imgSvc;


    
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


    public ProfileResponse getProfile(LoggedUserPayload requester) {
        return ProfileResponse.from(requireAccount(requester));
    }


    @Transactional
    public ProfileResponse changeName(LoggedUserPayload requester, @Valid EditNameRequest data) {
        User user = requireAccount(requester);
        user.setName(data.name());
        return ProfileResponse.from(user);
    }

    @Transactional
    public ProfileResponse changeDescription(LoggedUserPayload requester, @Valid EditDescriptionRequest data) {
        User user = requireAccount(requester);
        user.setDescription(data.description());
        return ProfileResponse.from(user);
    }


    @Transactional
    public void requestEmailChange(LoggedUserPayload requester, @Valid ChangeEmailRequest data) {
        User user = requireAccount(requester);

        if (!user.isEmailVerified()) throw new BusinessRuleException("Verifique o e-mail atual antes de trocá-lo.");
        if (user.getEmail().equalsIgnoreCase(data.newEmail())) throw new BusinessRuleException("O novo e-mail não pode ser igual ao atual.");
        if (usrRep.existsByEmail(data.newEmail())) throw new DuplicatedValueException("E-mail já cadastrado.");

        String code = eccSvc.newCode(user, data.newEmail());
        emlSvc.verificationEmail(data.newEmail(), code);
    }


    @Transactional
    public User confirmEmailChange(LoggedUserPayload requester, @Valid ConfirmEmailChangeRequest data) {
        User user = requireAccount(requester);
        EmailChangeCode code = eccSvc.getByUser(user);

        if (!pswEcd.matches(data.code(), code.getCode())) throw new BadCredentialsException("Código inválido.");
        if (usrRep.existsByEmail(code.getNewEmail())) throw new DuplicatedValueException("E-mail já cadastrado.");

        user.setEmail(code.getNewEmail());
        user.setEmailVerified(true);
        eccSvc.deleteCode(code);

        return user;
    }


    @Transactional
    public ProfileResponse setProfileImage(LoggedUserPayload requester, @Valid ImageRequest image) {
        User user = requireAccount(requester);

        if (user.getProfileImageUrl() != null) imgSvc.deleteImage(user.getProfileImageUrl(), StorageFileType.USER_PROFILE_PHOTO);

        String url = imgSvc.saveImage(image, String.valueOf(user.getId()), StorageFileType.USER_PROFILE_PHOTO);
        user.setProfileImageUrl(url);

        return ProfileResponse.from(user);
    }


    private User requireAccount(LoggedUserPayload requester) {
        if (requester == null || requester.email() == null || requester.email().endsWith("@anonymous.local")) {
            throw new BusinessRuleException("Acessos anônimos não possuem perfil.");
        }

        return usrRep.findByEmail(requester.email()).orElseThrow(() -> new ValueNotFoundException("Usuário não cadastrado."));
    }


    @Transactional
    public UserResponse newUser(@Valid RegisterRequest data, String clientIp) {
        if (!data.doAcceptTerms()) throw new BusinessRuleException("Os termos de uso devem ser aceitos.");
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

        trmSvc.acceptCurrentTerms(new LoggedUserPayload(user.getEmail()), clientIp);

        String code = evcSvc.newCode(user);
        emlSvc.verificationEmail(user.getEmail(), code);

        return UserResponse.from(user);
    }

    @Transactional
    public void changePassword(LoggedUserPayload requester, @Valid PasswordChangeRequest data) {
        
        User user = requireAccount(requester);

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
            case ANONYMOUS -> throw new BusinessRuleException("Acessos anônimos não podem ser verificados.");
        }
    }
}

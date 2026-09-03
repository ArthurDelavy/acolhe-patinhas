package com.ong.acolhepatinhas.api.emailverification;

import java.time.OffsetDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.exceptions.custom.ExpiredDataException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.utils.PasswordCode;

@Service
@Transactional(readOnly = true)
public class EmailVerificationCodeService {

    @Autowired
    private EmailVerificationCodeRepository evcRep;

    @Autowired
    private PasswordEncoder pswEcd;

    @Transactional
    public String newCode(User user) {

        String code = PasswordCode.generateCode();

        EmailVerificationCode evCode = evcRep.findByUser(user).orElseGet(EmailVerificationCode::new);

        evCode.setUser(user);
        evCode.setCode(pswEcd.encode(code));
        evCode.setExpiresAt(OffsetDateTime.now().plusHours(24));

        evcRep.save(evCode);

        return code;
    }

    @Transactional
    public EmailVerificationCode getByUser(User user) {
        EmailVerificationCode code = evcRep.findByUser(user).orElseThrow(() -> new ValueNotFoundException("Nenhum código de verificação solicitado para o usuário."));
        if (code.getExpiresAt().isBefore(OffsetDateTime.now())) {
            evcRep.delete(code);
            throw new ExpiredDataException("Código de verificação expirado.");
        }

        return code;
    }

    @Transactional
    public void deleteCode(EmailVerificationCode code) {
        if (evcRep.existsById(code.getId())) evcRep.delete(code);
    }
}

package com.ong.acolhepatinhas.api.emailchange;

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
public class EmailChangeCodeService {

    @Autowired
    private EmailChangeCodeRepository eccRep;

    @Autowired
    private PasswordEncoder pswEcd;


    @Transactional
    public String newCode(User user, String newEmail) {

        String code = PasswordCode.generateCode();

        EmailChangeCode changeCode = eccRep.findByUser(user).orElseGet(EmailChangeCode::new);

        changeCode.setUser(user);
        changeCode.setNewEmail(newEmail);
        changeCode.setCode(pswEcd.encode(code));
        changeCode.setExpiresAt(OffsetDateTime.now().plusHours(24));

        eccRep.save(changeCode);

        return code;
    }

    @Transactional
    public EmailChangeCode getByUser(User user) {
        EmailChangeCode code = eccRep.findByUser(user).orElseThrow(() -> new ValueNotFoundException("Nenhum código de troca de e-mail solicitado para o usuário."));
        if (code.getExpiresAt().isBefore(OffsetDateTime.now())) {
            eccRep.delete(code);
            throw new ExpiredDataException("Código de verificação expirado.");
        }

        return code;
    }

    @Transactional
    public void deleteCode(EmailChangeCode code) {
        if (eccRep.existsById(code.getId())) eccRep.delete(code);
    }
}


package com.ong.acolhepatinhas.api.passwordcode;

import java.time.OffsetDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Lazy;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.exceptions.custom.ExpiredDataException;
import com.ong.acolhepatinhas.api.exceptions.custom.ValueNotFoundException;
import com.ong.acolhepatinhas.api.user.User;
import com.ong.acolhepatinhas.api.user.UserService;
import com.ong.acolhepatinhas.api.utils.PasswordCode;

@Service
@Transactional(readOnly = true)
public class PasswordChangeCodeService {
    
    @Autowired
    private PasswordChangeCodeRepository pswRep;

    @Autowired @Lazy
    private UserService usrSvc;

    @Autowired
    private PasswordEncoder pswEcd;


    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public String newCode(User user) {

        String code = PasswordCode.generateCode();

        PasswordChangeCode pswCode = pswRep.findByUser(user).orElseGet(PasswordChangeCode::new);

        pswCode.setUser(user);
        pswCode.setCode(pswEcd.encode(code));
        pswCode.setExpiresAt(OffsetDateTime.now().plusMinutes(10));

        pswRep.save(pswCode);

        return code;
    }

    @Transactional
    public PasswordChangeCode getByUser(User user) {
        PasswordChangeCode code = pswRep.findByUser(user).orElseThrow(() -> new ValueNotFoundException("Nenhum código solicitado para o usuário."));
        if (code.getExpiresAt().isBefore(OffsetDateTime.now())) {
            pswRep.delete(code);
            throw new ExpiredDataException("Código expirado.");
        }

        return code;
    }

    @Transactional
    public void deleteCode(PasswordChangeCode code) {
        if (pswRep.existsById(code.getId())) pswRep.delete(code);
    }
}

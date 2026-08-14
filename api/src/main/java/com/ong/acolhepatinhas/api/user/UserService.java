package com.ong.acolhepatinhas.api.user;

import java.time.OffsetDateTime;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.ong.acolhepatinhas.api.auth.DTO.RegisterRequest;
import com.ong.acolhepatinhas.api.exceptions.custom.DuplicatedValueException;
import com.ong.acolhepatinhas.api.user.DTO.UserResponse;


@Service
@Transactional(readOnly = true)
public class UserService implements UserDetailsService {
    
    @Autowired
    private UserRepository usrRep;

    @Autowired
    private PasswordEncoder pswEcd;

    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        return usrRep.findByEmail(username).orElseThrow(() -> new UsernameNotFoundException("Usuário não cadastrado."));
    }

    @Transactional
    public UserResponse newUser(RegisterRequest data) {
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
}

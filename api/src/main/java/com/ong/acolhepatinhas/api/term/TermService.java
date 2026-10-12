package com.ong.acolhepatinhas.api.term;

import java.time.Instant;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.validation.annotation.Validated;

import com.ong.acolhepatinhas.api.term.agreement.TermAgreement;
import com.ong.acolhepatinhas.api.term.agreement.TermAgreementRepository;
import com.ong.acolhepatinhas.api.term.version.TermVersion;
import com.ong.acolhepatinhas.api.term.version.TermVersionRepository;
import com.ong.acolhepatinhas.api.user.User;

import lombok.RequiredArgsConstructor;

@Service
@Validated
@RequiredArgsConstructor
@Transactional(readOnly = true)
public class TermService {
    
    private final TermAgreementRepository tagRep;
    private final TermVersionRepository tvsRep;


    public boolean hasAcceptedCurrentTerms(int userId) {
        TermVersion currentTerm = tvsRep.findByIsCurrentTrue().orElseThrow(() -> new IllegalStateException("Nenhum termo ativo encontrado."));

        return tagRep.existsByUserIdAndTermVersionId(userId, currentTerm.getId());
    }


    @Transactional
    public void acceptCurrentTerms(User user, String ipAddress) {
     
        TermVersion currentTerm = tvsRep.findByIsCurrentTrue().orElseThrow(() -> new IllegalStateException("Nenhum termo ativo encontrado."));

        if (tagRep.existsByUserIdAndTermVersionId(user.getId(), currentTerm.getId())) return;

        TermAgreement agreement = TermAgreement.builder()
            .user(user)
            .termVersion(currentTerm)
            .acceptedAt(Instant.now())
            .ipAddress(ipAddress)
            .build();

        tagRep.save(agreement);
    }
}

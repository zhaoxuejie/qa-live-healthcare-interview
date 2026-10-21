package com.leansofx.qaserviceuser.repository;

import com.leansofx.qaserviceuser.entity.PatientToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface PatientTokenRepository extends JpaRepository<PatientToken, String> {

    Optional<PatientToken> findByTokenAndExpiresAtAfter(String token, LocalDateTime now);

    void deleteByToken(String token);
}

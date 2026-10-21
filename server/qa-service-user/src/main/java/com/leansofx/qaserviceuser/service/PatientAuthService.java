package com.leansofx.qaserviceuser.service;

import com.leansofx.qaserviceuser.dto.AuthResponse;
import com.leansofx.qaserviceuser.dto.PatientDto;
import com.leansofx.qaserviceuser.dto.PatientLoginRequest;
import com.leansofx.qaserviceuser.dto.PatientRegisterRequest;
import com.leansofx.qaserviceuser.entity.Patient;
import com.leansofx.qaserviceuser.entity.PatientToken;
import com.leansofx.qaserviceuser.exception.ApiException;
import com.leansofx.qaserviceuser.repository.PatientRepository;
import com.leansofx.qaserviceuser.repository.PatientTokenRepository;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.Base64;
import java.util.regex.Pattern;

@Service
public class PatientAuthService {

    private static final int TOKEN_TTL_DAYS = 7;
    private static final Pattern USERNAME_PATTERN = Pattern.compile("^[A-Za-z0-9_-]{4,32}$");

    private final PatientRepository patientRepository;
    private final PatientTokenRepository tokenRepository;
    private final BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder(10);
    private final SecureRandom secureRandom = new SecureRandom();

    public PatientAuthService(PatientRepository patientRepository,
                              PatientTokenRepository tokenRepository) {
        this.patientRepository = patientRepository;
        this.tokenRepository = tokenRepository;
    }

    @Transactional
    public AuthResponse register(PatientRegisterRequest request) {
        validateRegister(request);
        if (patientRepository.existsByUsername(request.username())) {
            throw new ApiException(HttpStatus.CONFLICT, 40900, "用户名已存在");
        }

        Patient patient = new Patient();
        patient.setUsername(request.username());
        patient.setPasswordHash(passwordEncoder.encode(request.password()));
        patient.setName(request.name().trim());
        patient.setBirthday(request.birthday());
        patient.setPhone(request.phone());
        patient.setGender(request.gender());
        patient = patientRepository.save(patient);

        return new AuthResponse(issueToken(patient.getId()), PatientDto.from(patient));
    }

    @Transactional
    public AuthResponse login(PatientLoginRequest request) {
        if (isBlank(request.username()) || isBlank(request.password())) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "用户名和密码不能为空");
        }
        Patient patient = patientRepository.findByUsername(request.username())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, 40100, "用户名或密码错误"));

        if (!passwordEncoder.matches(request.password(), patient.getPasswordHash())) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, 40100, "用户名或密码错误");
        }
        return new AuthResponse(issueToken(patient.getId()), PatientDto.from(patient));
    }

    @Transactional(readOnly = true)
    public PatientDto me(String token) {
        PatientToken patientToken = tokenRepository
                .findByTokenAndExpiresAtAfter(token, LocalDateTime.now())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, 40100, "登录已失效，请重新登录"));
        Patient patient = patientRepository.findById(patientToken.getPatientId())
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, 40100, "登录已失效，请重新登录"));
        return PatientDto.from(patient);
    }

    @Transactional
    public void logout(String token) {
        if (token != null) {
            tokenRepository.deleteByToken(token);
        }
    }

    private String issueToken(Long patientId) {
        byte[] bytes = new byte[32];
        secureRandom.nextBytes(bytes);
        String token = Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);

        PatientToken entity = new PatientToken();
        entity.setToken(token);
        entity.setPatientId(patientId);
        entity.setExpiresAt(LocalDateTime.now().plusDays(TOKEN_TTL_DAYS));
        tokenRepository.save(entity);
        return token;
    }

    private void validateRegister(PatientRegisterRequest request) {
        if (request.username() == null || !USERNAME_PATTERN.matcher(request.username()).matches()) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "用户名需为 4-32 位字母、数字、下划线或连字符");
        }
        if (request.password() == null || request.password().length() < 6 || request.password().length() > 64) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "密码长度需为 6-64 位");
        }
        if (isBlank(request.name()) || request.name().trim().length() > 64) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "姓名不能为空且不超过 64 字");
        }
        if (request.phone() != null && request.phone().length() > 32) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "手机号过长");
        }
        if (request.gender() != null && request.gender().length() > 16) {
            throw new ApiException(HttpStatus.BAD_REQUEST, 40000, "性别字段过长");
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}

package com.leansofx.qaserviceuser.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

import java.time.LocalDateTime;

/**
 * 患者登录令牌：不透明 token，默认 7 天有效。
 */
@Entity
@Table(name = "patient_token")
public class PatientToken {

    @Id
    @Column(length = 64)
    private String token;

    @Column(name = "patient_id", nullable = false)
    private Long patientId;

    @Column(name = "expires_at", nullable = false)
    private LocalDateTime expiresAt;

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public Long getPatientId() {
        return patientId;
    }

    public void setPatientId(Long patientId) {
        this.patientId = patientId;
    }

    public LocalDateTime getExpiresAt() {
        return expiresAt;
    }

    public void setExpiresAt(LocalDateTime expiresAt) {
        this.expiresAt = expiresAt;
    }
}

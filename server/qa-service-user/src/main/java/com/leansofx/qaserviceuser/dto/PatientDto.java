package com.leansofx.qaserviceuser.dto;

import com.leansofx.qaserviceuser.entity.Patient;

import java.time.LocalDate;

/**
 * 患者信息（响应），不包含密码哈希。
 */
public record PatientDto(
        Long id,
        String username,
        String name,
        LocalDate birthday,
        String phone,
        String gender
) {

    public static PatientDto from(Patient patient) {
        return new PatientDto(
                patient.getId(),
                patient.getUsername(),
                patient.getName(),
                patient.getBirthday(),
                patient.getPhone(),
                patient.getGender()
        );
    }
}

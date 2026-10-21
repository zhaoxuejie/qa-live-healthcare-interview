package com.leansofx.qaserviceuser.dto;

import com.leansofx.qaserviceuser.entity.Doctor;

import java.util.List;

/**
 * 医生列表返回结构：不包含 password 等敏感字段。
 */
public record DoctorDto(
        String id,
        String username,
        String name,
        String title,
        String department,
        String avatar,
        String experience,
        List<String> specialties,
        Boolean isActive
) {

    public static DoctorDto from(Doctor doctor) {
        return new DoctorDto(
                doctor.getId(),
                doctor.getUsername(),
                doctor.getName(),
                doctor.getTitle(),
                doctor.getDepartment(),
                doctor.getAvatar(),
                doctor.getExperience(),
                doctor.getSpecialties() == null ? List.of() : List.copyOf(doctor.getSpecialties()),
                doctor.getIsActive()
        );
    }
}

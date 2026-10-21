package com.leansofx.qaserviceuser.dto;

import java.time.LocalDate;

public record PatientRegisterRequest(
        String username,
        String password,
        String name,
        LocalDate birthday,
        String phone,
        String gender
) {
}

package com.leansofx.qaserviceuser.controller;

import com.leansofx.qaserviceuser.common.ApiResponse;
import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.service.DoctorService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/doctors")
public class DoctorController {

    private final DoctorService doctorService;

    public DoctorController(DoctorService doctorService) {
        this.doctorService = doctorService;
    }

    /**
     * 医生列表。active=true 时仅返回在诊医生。
     */
    @GetMapping
    public ApiResponse<List<DoctorDto>> list(
            @RequestParam(name = "active", required = false) Boolean active) {
        return ApiResponse.ok(doctorService.listDoctors(Boolean.TRUE.equals(active)));
    }
}

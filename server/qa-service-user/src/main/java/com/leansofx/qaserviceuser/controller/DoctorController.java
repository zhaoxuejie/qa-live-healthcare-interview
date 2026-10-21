package com.leansofx.qaserviceuser.controller;

import com.leansofx.qaserviceuser.common.ApiResponse;
import com.leansofx.qaserviceuser.dto.DoctorDto;
import com.leansofx.qaserviceuser.dto.DoctorLoginRequest;
import com.leansofx.qaserviceuser.service.DoctorService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
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

    /**
     * 医生登录。成功返回医生信息（不含密码），失败统一 401。
     */
    @PostMapping("/login")
    public ResponseEntity<ApiResponse<DoctorDto>> login(@RequestBody DoctorLoginRequest request) {
        return doctorService.login(request.username(), request.password())
                .map(doctor -> ResponseEntity.ok(ApiResponse.ok(doctor)))
                .orElseGet(() -> ResponseEntity.status(HttpStatus.UNAUTHORIZED)
                        .body(ApiResponse.error(40100, "用户名或密码错误")));
    }
}

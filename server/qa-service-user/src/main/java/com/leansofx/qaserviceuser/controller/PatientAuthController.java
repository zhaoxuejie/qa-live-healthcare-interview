package com.leansofx.qaserviceuser.controller;

import com.leansofx.qaserviceuser.common.ApiResponse;
import com.leansofx.qaserviceuser.dto.AuthResponse;
import com.leansofx.qaserviceuser.dto.PatientDto;
import com.leansofx.qaserviceuser.dto.PatientLoginRequest;
import com.leansofx.qaserviceuser.dto.PatientRegisterRequest;
import com.leansofx.qaserviceuser.exception.ApiException;
import com.leansofx.qaserviceuser.service.PatientAuthService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth/patient")
public class PatientAuthController {

    private final PatientAuthService authService;

    public PatientAuthController(PatientAuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@RequestBody PatientRegisterRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(ApiResponse.ok(authService.register(request)));
    }

    @PostMapping("/login")
    public ApiResponse<AuthResponse> login(@RequestBody PatientLoginRequest request) {
        return ApiResponse.ok(authService.login(request));
    }

    @GetMapping("/me")
    public ApiResponse<PatientDto> me(
            @RequestHeader(name = "Authorization", required = false) String authorization) {
        String token = extractToken(authorization);
        if (token == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, 40100, "未登录");
        }
        return ApiResponse.ok(authService.me(token));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout(
            @RequestHeader(name = "Authorization", required = false) String authorization) {
        authService.logout(extractToken(authorization));
        return ResponseEntity.noContent().build();
    }

    private String extractToken(String authorization) {
        if (authorization == null || !authorization.startsWith("Bearer ")) {
            return null;
        }
        String token = authorization.substring("Bearer ".length()).trim();
        return token.isEmpty() ? null : token;
    }
}

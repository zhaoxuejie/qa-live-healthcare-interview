package com.leansofx.qaserviceuser.common;

/**
 * 统一响应体：成功 code=0，失败使用业务码（如 40000/50000）。
 */
public record ApiResponse<T>(int code, String message, T data) {

    public static <T> ApiResponse<T> ok(T data) {
        return new ApiResponse<>(0, "ok", data);
    }

    public static <T> ApiResponse<T> error(int code, String message) {
        return new ApiResponse<>(code, message, null);
    }
}

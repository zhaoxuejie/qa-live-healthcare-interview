package com.leansofx.qaserviceuser.exception;

import org.springframework.http.HttpStatus;

/**
 * 带业务码的异常，由 GlobalExceptionHandler 转换为统一响应体。
 */
public class ApiException extends RuntimeException {

    private final HttpStatus status;
    private final int code;

    public ApiException(HttpStatus status, int code, String message) {
        super(message);
        this.status = status;
        this.code = code;
    }

    public HttpStatus getStatus() {
        return status;
    }

    public int getCode() {
        return code;
    }
}

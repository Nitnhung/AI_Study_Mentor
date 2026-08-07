package com.brightpath.aimentor.exception;

import com.brightpath.aimentor.dto.ApiResponse;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.*;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(MethodArgumentNotValidException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleValidation(MethodArgumentNotValidException e) {
        StringBuilder msg = new StringBuilder();
        e.getBindingResult().getFieldErrors().forEach(err -> {
            String field = err.getField();
            switch (field) {
                case "email" -> msg.append("Vui lòng nhập email hợp lệ. ");
                case "password" -> msg.append("Vui lòng nhập mật khẩu. ");
                default -> msg.append("Trường ").append(field).append(" không hợp lệ. ");
            }
        });
        return ApiResponse.error(msg.toString().trim());
    }

    @ExceptionHandler(RuntimeException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public ApiResponse<Object> handleRuntime(RuntimeException e) {
        return ApiResponse.error(e.getMessage());
    }

    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ApiResponse<Object> handleGeneral(Exception e) {
        return ApiResponse.error("Lỗi hệ thống. Vui lòng thử lại.");
    }
}

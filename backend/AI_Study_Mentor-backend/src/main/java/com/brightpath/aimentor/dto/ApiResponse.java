package com.brightpath.aimentor.dto;

public class ApiResponse<T> {
    private boolean success; private String message; private T data;
    public ApiResponse() {} public ApiResponse(boolean s, String m, T d) { success=s; message=m; data=d; }
    public static <T> ApiResponse<T> ok(T data) { return new ApiResponse<>(true, "OK", data); }
    public static <T> ApiResponse<T> ok(String msg, T data) { return new ApiResponse<>(true, msg, data); }
    public static <T> ApiResponse<T> error(String msg) { return new ApiResponse<>(false, msg, null); }
    public boolean isSuccess() { return success; } public String getMessage() { return message; } public T getData() { return data; }
}

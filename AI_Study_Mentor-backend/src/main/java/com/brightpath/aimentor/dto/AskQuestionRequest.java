package com.brightpath.aimentor.dto;

public class AskQuestionRequest {
    private String contentText, imageBase64, imageMimeType;
    public String getContentText() { return contentText; } public void setContentText(String v) { contentText = v; }
    public String getImageBase64() { return imageBase64; } public void setImageBase64(String v) { imageBase64 = v; }
    public String getImageMimeType() { return imageMimeType; } public void setImageMimeType(String v) { imageMimeType = v; }
}

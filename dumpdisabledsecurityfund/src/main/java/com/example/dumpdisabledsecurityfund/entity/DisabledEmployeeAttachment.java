package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class DisabledEmployeeAttachment {
    private Long id;
    private Long employeeId;
    private String fileName;
    private String fileUrl;
    private Long fileSize;
    private String fileType;
    private String uploadTime;
    private String createTime;
}
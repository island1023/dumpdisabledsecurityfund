package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class OperationLog {
    private Long id;
    private Long userId;
    private String operationType;
    private String targetTable;
    private Long targetId;
    private String detail;
    private String ipAddress;
    private String createTime;
}
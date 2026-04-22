package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class DisabledAudit {
    private Long id;
    private Long companyId;
    private Integer year;
    private String employeeName;
    private String idCard;
    private Integer auditStatus;
    private Long auditorId;
    private String auditTime;
}
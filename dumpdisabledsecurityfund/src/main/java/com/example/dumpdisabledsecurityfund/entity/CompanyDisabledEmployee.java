package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class CompanyDisabledEmployee {
    private Long id;
    private Long companyId;
    private String name;
    private String idCard;
    private String disabilityCertNo;
    private String disabilityType;
    private String disabilityLevel;
    private String jobPosition;
    private String entryDate;
    private Integer isActive;
    private String auditPassTime;
    private String createTime;
    private String updateTime;
}
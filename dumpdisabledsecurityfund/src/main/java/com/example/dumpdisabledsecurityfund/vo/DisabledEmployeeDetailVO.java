package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class DisabledEmployeeDetailVO {
    private Long id;
    private String name;
    private String idCard;
    private String disabilityCertNo;
    private String disabilityType;
    private String disabilityLevel;
    private String jobPosition;
    private String entryDate;
    private Integer isActive;
    private String isActiveName;
    private String auditPassTime;
    private String createTime;
    private String updateTime;
}

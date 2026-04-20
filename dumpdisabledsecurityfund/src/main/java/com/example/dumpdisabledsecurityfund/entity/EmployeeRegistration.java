package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class EmployeeRegistration {
    private Long id;
    private Long companyId;
    private Integer year;
    private String name;
    private String idCard;
    private Integer isDisabled;
    private String disabilityCertNo;
    private String jobPosition;
    private String entryDate;
    private Integer status;
    private String createTime;
    private String updateTime;
}
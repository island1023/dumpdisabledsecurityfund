package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class EmployeeVO {
    private Long id;
    private Long companyId;
    private String companyName;
    private String name;
    private String idCard;
    private String jobPosition;
    private String entryDate;
    private Integer isDisabled;
    private String disabilityLevel;
    private String status;
}
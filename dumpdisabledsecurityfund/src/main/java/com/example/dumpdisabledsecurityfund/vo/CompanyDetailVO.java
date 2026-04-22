package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class CompanyDetailVO {
    private Long id;
    private String unifiedSocialCreditCode;
    private String name;
    private String legalPerson;
    private String contactPhone;
    private String industry;
    private String establishDate;
    private String address;
    private Integer employeeCount;
    private Integer disabledCount;
    private String district;
    private Integer status;
    private String createTime;
    private String updateTime;
    private Integer totalEmployees;
    private Integer disabledEmployees;
    private String statusName;
    private String regionName;
}

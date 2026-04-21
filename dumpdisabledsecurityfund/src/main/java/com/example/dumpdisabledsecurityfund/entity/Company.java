package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class Company {
    private Long id;
    private String unifiedSocialCreditCode;
    private String name;
    private Long regionId;
    private String legalPerson;
    private String contactPhone;
    private String industry;
    private String establishDate;
    private String address;
    private Integer employeeCount;
    private Integer status;
    private String createTime;
    private String updateTime;
}
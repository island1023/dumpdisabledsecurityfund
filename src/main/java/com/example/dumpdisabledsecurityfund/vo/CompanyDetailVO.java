package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class CompanyDetailVO {
    private Long id;
    private String unifiedSocialCreditCode;
    private String name;
    private Long regionId;
    private String regionName;
    private String legalPerson;
    private String contactPhone;
    private String industry;
    private String establishDate;
    private String address;
    private Integer totalEmployees;
    private Integer disabledEmployees;
    private Integer status;
    private String statusName;
    private String createTime;
    private String updateTime;
}

package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class CompanyVO {
    private Long id;
    private String unifiedSocialCreditCode;
    private String name;
    private String regionName;
    private String legalPerson;
    private String contactPhone;
    private Integer status;
    private String createTime;
}
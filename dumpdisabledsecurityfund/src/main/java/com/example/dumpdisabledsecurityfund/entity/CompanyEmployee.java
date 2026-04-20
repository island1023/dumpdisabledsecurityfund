package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class CompanyEmployee {
    private Long id;
    private Long companyId;
    private String name;
    private String idCard;
    private String jobPosition;
    private String entryDate;
    private Integer isActive;
    private String createTime;
    private String updateTime;
}
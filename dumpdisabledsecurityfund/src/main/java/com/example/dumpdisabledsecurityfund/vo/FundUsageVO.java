package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class FundUsageVO {
    private Long id;
    private String projectName;
    private Double amount;
    private String usageDate;
    private String regionName;
    private String description;
    private String auditStatus;
}
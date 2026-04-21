package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class FundUsage {
    private Long id;
    private String projectName;
    private Double amount;
    private String usageDate;
    private Long regionId;
    private String description;
    private Integer auditStatus;
    private Long auditorId;
    private String auditTime;
}
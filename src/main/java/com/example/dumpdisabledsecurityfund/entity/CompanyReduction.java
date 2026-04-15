package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class CompanyReduction {
    private Long id;
    private Long companyId;
    private Integer year;
    private Integer applyType;
    private Double applyAmount;
    private String reason;
    private Integer auditStatus;
    private Long auditorId;
    private String auditOpinion;
    private String auditTime;
    private String createTime;
    private String updateTime;
}
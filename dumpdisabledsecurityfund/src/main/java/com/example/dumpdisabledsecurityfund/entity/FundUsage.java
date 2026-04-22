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
    /** 项目类型（就业服务、职业培训等），供领导端展示 */
    private String projectType;
    private Integer beneficiaryCount;
    /** 拨付展示状态：已拨付、拨付中、已验收 */
    private String usageStatus;
}
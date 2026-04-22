package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

/**
 * 单位残疾职工实体类（用于单位内部管理）
 * 注意：此实体用于单位负责人管理本单位残疾职工
 * 审批流程请使用 DisabledEmployee
 */
@Data
public class CompanyDisabledEmployee {
    private Long id;
    private Long companyId;
    private String name;
    private String idCard;
    private String disabilityCertNo;
    private String disabilityType;
    private String disabilityLevel;
    private String jobPosition;
    private String entryDate;
    private Integer isActive;
    private String auditPassTime;
    private String createTime;
    private String updateTime;
}
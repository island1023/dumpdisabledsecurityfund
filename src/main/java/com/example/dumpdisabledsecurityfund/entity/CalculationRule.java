package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class CalculationRule {
    private Long id;
    private String ruleName;
    private Integer applyYear;
    private Double requiredRatio;
    private String formulaJson;
    private Integer isActive;
    private String effectiveTime;
    private String expireTime;
    private String createTime;
    private String updateTime;
}
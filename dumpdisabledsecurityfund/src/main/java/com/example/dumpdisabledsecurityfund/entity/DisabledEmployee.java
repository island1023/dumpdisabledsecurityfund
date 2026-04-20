package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 残疾职工实体类
 */
@Data
public class DisabledEmployee {
    private Long id;
    private Long companyId;
    private String companyName;
    private String name;
    private String idCard;
    private String disabilityType;
    private String disabilityLevel;
    private String hireDate;
    private Integer year;
    private Integer status; // 0-待审核, 1-已通过, 2-已驳回
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

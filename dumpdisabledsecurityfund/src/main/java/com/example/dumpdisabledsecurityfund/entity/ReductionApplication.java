package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

import java.time.LocalDateTime;

/**
 * 减免缓申请实体类
 */
@Data
public class ReductionApplication {
    private Long id;
    private Long companyId;
    private String companyName;
    private String reductionType; // 减免/缓缴
    private Integer applyYear;
    private Double applyAmount;
    private String applyReason;
    private String attachment;
    private Integer status; // 0-待审核, 1-已通过, 2-已驳回
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}

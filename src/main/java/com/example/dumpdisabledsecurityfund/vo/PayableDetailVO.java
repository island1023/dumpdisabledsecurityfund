package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class PayableDetailVO {
    private Long id;
    private Long companyId;
    private String companyName;
    private Integer year;
    private Integer totalEmployeeCount;
    private Integer disabledEmployeeCount;
    private Double requiredRatio;
    private Double calculatedAmount;
    private Integer status;
    private String statusText;
}
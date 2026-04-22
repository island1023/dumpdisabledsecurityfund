package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class PayableAmount {
    private Long id;
    private Long companyId;
    private Integer year;
    private Integer totalEmployeeCount;
    private Integer disabledEmployeeCount;
    private Double requiredRatio;
    private Double calculatedAmount;
    private Double reductionAmount;
    private Double payableAmount;
    private Double paidAmount;
    private Integer paymentStatus;
    private Integer status;
    private String confirmTime;
}
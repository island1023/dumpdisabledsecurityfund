package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class PayableDetailVO {
    private Long id;
    private Long companyId;
    private String companyName;
    private String creditCode;
    private String legalPerson;
    private String registerAddress;
    private String establishDate;
    private String phone;
    private Integer year;
    private Integer employeeCount;
    private Integer disabledCount;
    private Double requiredRatio;
    private Double standardAmount;
    private Double reductionAmount;
    private Double payableAmount;
    private Double paidAmount;
    private String status;
    private Boolean taxDataMatch;
    private String voucher;
}
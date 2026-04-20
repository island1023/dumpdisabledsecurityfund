package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class ReportStatisticsVO {
    private Integer year;
    private Long totalCompanyCount;
    private Long declaredCompanyCount;
    private Long paidCompanyCount;
    private Double totalPayableAmount;
    private Double totalPaidAmount;
    private Double totalFundUsage;
    private Long disabledEmployeeCount;
}
package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class PaymentStatisticsVO {
    private Double paidAmount;
    private Double pendingAmount;
    private Double totalAmount;
    private Integer year;
}

package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class PaymentRecordVO {
    private Long id;
    private Long payableId;
    private String companyName;
    private Integer year;
    private Double actualAmount;
    private String paymentDate;
    private String source;
    private String status;
}
package com.example.dumpdisabledsecurityfund.entity;

import lombok.Data;

@Data
public class PaymentRecord {
    private Long id;
    private Long payableId;
    private Double actualAmount;
    private String paymentDate;
    private Integer source;
    private Long confirmUserId;
    private Integer status;
}
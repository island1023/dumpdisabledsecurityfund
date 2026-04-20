package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class CollectionStatisticsVO {
    private Integer totalUnits;
    private Integer paidUnits;
    private Integer unpaidUnits;
    private Double totalAmount;
    private Double paidAmount;
    private Double reductionAmount;
}

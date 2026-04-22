package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;

@Data
public class CollectionVO {
    private Long id;
    private Long companyId;
    private String companyName;
    private String creditCode;
    private String legalPerson;
    private String registerAddress;
    private String establishDate;
    private String phone;
    private Integer totalEmployeeCount;
    private Integer employeeCount;
    private Integer disabledCount;
    private Integer year;
    private Double standardAmount;
    private Double reductionAmount;
    private Double payableAmount;
    private Double paidAmount;
    private String status;
    private Boolean taxDataMatch;
    private String voucher;
}

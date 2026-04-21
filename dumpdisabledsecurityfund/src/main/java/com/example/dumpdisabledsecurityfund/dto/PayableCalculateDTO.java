package com.example.dumpdisabledsecurityfund.dto;

import lombok.Data;

@Data
public class PayableCalculateDTO {
    private Long companyId;
    private Integer year;
    private Integer totalEmployeeCount;
    private Integer disabledEmployeeCount;
}
package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class TaxDataImportDTO {

    @NotNull(message = "公司ID不能为空")
    private Long companyId;

    @NotNull(message = "年度不能为空")
    @Min(value = 2000, message = "年度格式错误")
    private Integer year;

    @NotNull(message = "职工总数不能为空")
    @Min(value = 0, message = "职工总数不能为负数")
    private Integer totalEmployeeCount;

    @NotNull(message = "残疾人数不能为空")
    @Min(value = 0, message = "残疾人数不能为负数")
    private Integer disabledEmployeeCount;

    @NotNull(message = "应缴金额不能为空")
    @Min(value = 0, message = "应缴金额不能为负数")
    private Double calculatedAmount;
}

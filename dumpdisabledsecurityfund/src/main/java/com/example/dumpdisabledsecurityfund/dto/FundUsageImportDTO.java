package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class FundUsageImportDTO {

    @NotBlank(message = "项目名称不能为空")
    private String projectName;

    @NotNull(message = "金额不能为空")
    @Min(value = 0, message = "金额不能为负数")
    private Double amount;

    @NotBlank(message = "支出日期不能为空")
    private String usageDate;

    @NotNull(message = "地区ID不能为空")
    private Long regionId;

    private String description;
}

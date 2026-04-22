package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class ReductionApplyDTO {

    @NotNull(message = "公司ID不能为空")
    private Long companyId;

    @NotNull(message = "申请年度不能为空")
    private Integer year;

    @NotNull(message = "申请类型不能为空")
    private Integer applyType;

    private Double applyAmount;

    @NotBlank(message = "申请理由不能为空")
    private String reason;

    private String attachment;
}

package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class CompanyImportDTO {

    @NotBlank(message = "统一社会信用代码不能为空")
    private String unifiedSocialCreditCode;

    @NotBlank(message = "单位名称不能为空")
    private String name;

    @NotNull(message = "所属地区ID不能为空")
    private Long regionId;

    private String legalPerson;

    private String contactPhone;
}

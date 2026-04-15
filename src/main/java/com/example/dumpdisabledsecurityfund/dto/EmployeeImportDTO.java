package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class EmployeeImportDTO {

    @NotNull(message = "公司ID不能为空")
    private Long companyId;

    @NotBlank(message = "职工姓名不能为空")
    private String name;

    @NotBlank(message = "身份证号不能为空")
    private String idCard;

    private String jobPosition;

    private String entryDate;
}

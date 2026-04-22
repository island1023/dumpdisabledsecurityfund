package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.ImportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;


/**
 * 统一导入控制器
 */
@Tag(name = "数据导入", description = "通用的数据导入接口，支持多种数据类型")
@RestController
@RequestMapping("/import")
public class ImportController {
    @Resource
    private ImportService importService;

    @Operation(summary = "通用数据导入", description = "根据类型参数导入不同类型的数据（企业、员工、税务等）")
    @PostMapping("/importAll")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importAll(
            @Parameter(description = "Excel文件", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(description = "数据类型：company-企业，disabled_employee-残疾人员工，normal_employee-正常员工，tax_data-税务数据", required = true, example = "company")
            @RequestParam String type) {
        return importService.importAll(file, type);
    }
}

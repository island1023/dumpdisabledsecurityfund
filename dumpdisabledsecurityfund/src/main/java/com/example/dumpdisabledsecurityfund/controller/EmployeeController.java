package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * 员工控制器
 */
@Tag(name = "员工管理", description = "残疾人员工和正常员工的导入功能")
@RestController
@RequestMapping("/employee")
public class EmployeeController {
    @Resource
    private EmployeeService employeeService;

    @Operation(summary = "导入残疾人员工", description = "通过Excel文件批量导入残疾人员工数据，用于残保金计算")
    @PostMapping("/importDisabled")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importDisabled(
            @Parameter(description = "Excel文件，包含残疾人证号、姓名、残疾等级等信息", required = true)
            MultipartFile file) {
        return employeeService.importDisabled(file);
    }

    @Operation(summary = "导入正常员工", description = "通过Excel文件批量导入正常员工数据，用于计算在职职工总数")
    @PostMapping("/importNormal")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importNormal(
            @Parameter(description = "Excel文件，包含员工姓名、身份证号、入职日期等信息", required = true)
            MultipartFile file) {
        return employeeService.importNormal(file);
    }
}

package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

/**
 * 员工控制器
 */
@Tag(name = "员工管理", description = "残疾人员工和正常员工的导入、残疾人证管理功能")
@RestController
@RequestMapping("/employee")
public class EmployeeController {
    @Resource
    private EmployeeService employeeService;

    @Operation(summary = "导入残疾人员工", description = "通过Excel文件批量导入残疾人员工数据")
    @PostMapping("/importDisabled")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importDisabled(
            @Parameter(description = "Excel文件，包含企业ID、姓名、身份证号、残疾证号等信息", required = true)
            @RequestParam("file") MultipartFile file) {
        return employeeService.importDisabled(file);
    }

    @Operation(summary = "导入正常员工", description = "通过Excel文件批量导入正常员工数据")
    @PostMapping("/importNormal")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importNormal(
            @Parameter(description = "Excel文件，包含企业ID、员工姓名、身份证号等信息", required = true)
            @RequestParam("file") MultipartFile file) {
        return employeeService.importNormal(file);
    }

    @Operation(summary = "批量导入单位全体职工", description = "通过Excel文件一次性导入所有职工（包括残疾职工和普通职工）")
    @PostMapping("/importAllEmployees")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> importAllEmployees(
            @Parameter(description = "Excel文件，包含姓名、身份证号、工作岗位、入职日期、是否残疾、残疾证号、残疾等级", required = true)
            @RequestParam("file") MultipartFile file) {
        return employeeService.importAllEmployees(file);
    }

    @Operation(summary = "上传残疾人证", description = "上传残疾职工的残疾人证照片，每个职工只能上传一张")
    @PostMapping("/uploadDisabilityCertificate")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> uploadDisabilityCertificate(
            @Parameter(description = "残疾人证图片文件（JPG/PNG/GIF）", required = true)
            @RequestParam("file") MultipartFile file,
            @Parameter(description = "职工ID", required = true, example = "1")
            @RequestParam("employeeId") Long employeeId) {
        return employeeService.uploadDisabilityCertificate(file, employeeId);
    }

    @Operation(summary = "查询残疾人证", description = "获取指定残疾职工的残疾人证信息")
    @GetMapping("/disabilityCertificate/{employeeId}")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> getDisabilityCertificate(
            @Parameter(description = "职工ID", required = true, example = "1")
            @PathVariable Long employeeId) {
        return employeeService.getDisabilityCertificate(employeeId);
    }

    @Operation(summary = "删除残疾人证", description = "删除指定的残疾人证")
    @DeleteMapping("/disabilityCertificate/{attachmentId}")
    @RequirePermission(roles = {"admin_system", "admin_city", "company_user"})
    public Result<?> deleteDisabilityCertificate(
            @Parameter(description = "附件ID", required = true, example = "1")
            @PathVariable Long attachmentId) {
        return employeeService.deleteDisabilityCertificate(attachmentId);
    }
}
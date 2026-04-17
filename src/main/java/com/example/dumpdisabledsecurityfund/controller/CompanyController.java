package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.CompanyService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "企业管理", description = "企业信息的导入、查询和管理功能")
@RestController
@RequestMapping("/company")
public class CompanyController {
    @Resource
    private CompanyService companyService;

    @Operation(summary = "查询企业列表", description = "获取企业列表，支持关键词搜索和分页")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> list(
            @Parameter(description = "搜索关键词", example = "科技")
            @RequestParam(required = false) String keyword,
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer pageNum,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return companyService.list(keyword, pageNum, pageSize);
    }

    @Operation(summary = "获取企业详情", description = "根据ID获取企业详细信息")
    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> getDetail(
            @Parameter(description = "企业ID", required = true, example = "1")
            @PathVariable Long id) {
        return companyService.getDetail(id);
    }

    @Operation(summary = "导入企业信息", description = "通过Excel文件批量导入企业基础数据")
    @PostMapping("/importExcel")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importExcel(
            @Parameter(description = "Excel文件", required = true)
            MultipartFile file) {
        return companyService.importExcel(file);
    }
}

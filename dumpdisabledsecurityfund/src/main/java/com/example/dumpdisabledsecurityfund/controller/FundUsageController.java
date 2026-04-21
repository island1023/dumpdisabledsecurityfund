package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.FundUsageService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

/**
 * 资金使用控制器
 */
@Tag(name = "资金使用管理", description = "残保金使用情况的数据导入")
@RestController
@RequestMapping("/fundUsage")
public class FundUsageController {
    @Resource
    private FundUsageService fundUsageService;

    @Operation(summary = "查询资金使用列表", description = "按年份和地区筛选资金使用记录，供领导和管理员查看")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public Result<?> list(
            @Parameter(description = "统计年度，可选", example = "2025")
            @RequestParam(required = false) Integer year,
            @Parameter(description = "地区ID，可选", example = "510104")
            @RequestParam(required = false) Long regionId) {
        return fundUsageService.list(year, regionId);
    }

    @Operation(summary = "导入资金使用数据", description = "通过Excel文件批量导入残保金使用情况，包括扶持奖励、补贴等支出记录")
    @PostMapping("/importExcel")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importExcel(
            @Parameter(description = "Excel文件，包含使用单位、金额、用途等信息", required = true)
            MultipartFile file) {
        return fundUsageService.importExcel(file);
    }
}

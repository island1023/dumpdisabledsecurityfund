package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.ReportService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 报表控制器
 */
@Tag(name = "统计报表", description = "残保金统计报表和数据汇总功能")
@RestController
@RequestMapping("/report")
public class ReportController {
    @Resource
    private ReportService reportService;

    @Operation(summary = "获取统计数据", description = "查询指定年度的残保金统计数据，包括应征总额、实缴总额、减免金额、企业数量等")
    @GetMapping("/statistics")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public Result<?> statistics(
            @Parameter(description = "统计年度，默认当前年度", example = "2024")
            @RequestParam(required = false) Integer year) {
        return reportService.getStatistics(year);
    }
}

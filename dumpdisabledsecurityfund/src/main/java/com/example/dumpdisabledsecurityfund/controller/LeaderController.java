package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.LeaderService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@Tag(name = "领导端", description = "区级/市级领导单位档案、残保金使用、统计报表（实时计算）")
@RestController
@RequestMapping("/leader")
public class LeaderController {

    @Resource
    private LeaderService leaderService;

    @Operation(summary = "单位档案列表", description = "按领导数据范围分页查询单位，关联职工与应缴年度摘要")
    @GetMapping("/archive/companies")
    @RequirePermission(roles = {"leader"})
    public Result<?> archiveCompanies(
            @Parameter(description = "关键词：单位名称或统一社会信用代码")
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false, defaultValue = "1") Integer pageNum,
            @RequestParam(required = false, defaultValue = "50") Integer pageSize) {
        return leaderService.listArchiveCompanies(keyword, pageNum, pageSize);
    }

    @Operation(summary = "单位档案详情", description = "基本信息、历年应缴与实缴、减免缓申请记录")
    @GetMapping("/archive/companies/{companyId}")
    @RequirePermission(roles = {"leader"})
    public Result<?> archiveCompanyDetail(
            @Parameter(description = "单位ID", required = true) @PathVariable Long companyId) {
        return leaderService.getArchiveCompanyDetail(companyId);
    }

    @Operation(summary = "残保金使用项目", description = "已审批通过的资金使用记录（可按区过滤）")
    @GetMapping("/fund-usage")
    @RequirePermission(roles = {"leader"})
    public Result<?> fundUsage(
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String projectType) {
        return leaderService.listFundUsage(keyword, projectType);
    }

    @Operation(summary = "统计报表（实时计算）", description = "类型：UNIT_INFO / UNPAID_UNIT / PAYMENT_STAT / RELIEF_STAT")
    @GetMapping("/reports")
    @RequirePermission(roles = {"leader"})
    public Result<?> reports(
            @RequestParam String type,
            @RequestParam(required = false) Integer year,
            @RequestParam(required = false) Integer month) {
        return leaderService.listExternalReportRows(type, year, month);
    }
}

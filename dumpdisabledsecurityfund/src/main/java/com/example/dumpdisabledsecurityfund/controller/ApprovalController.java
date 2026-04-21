package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.ApprovalService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

/**
 * 审批管理控制器
 */
@Tag(name = "审批管理", description = "残疾职工和减免缓申请的审批管理")
@RestController
@RequestMapping("/approval")
public class ApprovalController {

    @Resource
    private ApprovalService approvalService;

    @Operation(summary = "获取待审批列表", description = "获取当前管理员待审批的列表（残疾职工和减免缓申请）")
    @GetMapping("/pending")
    @RequirePermission(roles = {"admin_city", "admin_district"})
    public Result<?> getPendingList(
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize,
            @Parameter(description = "类型筛选：disabled-残疾职工, reduction-减免缓, all-全部")
            @RequestParam(required = false, defaultValue = "all") String type) {
        return approvalService.getPendingList(page, pageSize, type);
    }

    @Operation(summary = "审批通过", description = "通过指定的审批申请")
    @PostMapping("/{approvalId}/approve")
    @RequirePermission(roles = {"admin_city", "admin_district"})
    public Result<?> approve(
            @Parameter(description = "审批ID", required = true, example = "1")
            @PathVariable Long approvalId) {
        return approvalService.approve(approvalId);
    }

    @Operation(summary = "审批驳回", description = "驳回指定的审批申请")
    @PostMapping("/{approvalId}/reject")
    @RequirePermission(roles = {"admin_city", "admin_district"})
    public Result<?> reject(
            @Parameter(description = "审批ID", required = true, example = "1")
            @PathVariable Long approvalId,
            @Parameter(description = "驳回原因", required = true)
            @RequestBody Map<String, String> request) {
        String reason = request.get("reason");
        return approvalService.reject(approvalId, reason);
    }

    @Operation(summary = "获取审批详情", description = "获取指定审批申请的详细信息")
    @GetMapping("/{approvalId}")
    @RequirePermission(roles = {"admin_city", "admin_district", "company_user"})
    public Result<?> getDetail(
            @Parameter(description = "审批ID", required = true, example = "1")
            @PathVariable Long approvalId) {
        return approvalService.getDetail(approvalId);
    }

    @Operation(summary = "获取审批统计", description = "获取当前管理员的审批统计信息")
    @GetMapping("/statistics")
    @RequirePermission(roles = {"admin_city", "admin_district"})
    public Result<?> getStatistics() {
        return approvalService.getStatistics();
    }
}

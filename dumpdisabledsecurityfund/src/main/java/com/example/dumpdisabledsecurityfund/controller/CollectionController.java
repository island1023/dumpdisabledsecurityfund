package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.CollectionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

/**
 * 征收核算控制器 - 适配前端需求
 */
@Tag(name = "征收核算", description = "征收核算列表、统计、核销功能")
@RestController
@RequestMapping("/collection")
public class CollectionController {

    @Resource
    private CollectionService collectionService;

    @Operation(summary = "获取征收统计", description = "获取指定年度的征收统计数据")
    @GetMapping("/statistics")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> getStatistics(
            @Parameter(description = "年度", example = "2025")
            @RequestParam(required = false) Integer year) {
        return collectionService.getStatistics(year);
    }

    @Operation(summary = "获取征收列表", description = "获取征收记录列表，支持分页和筛选")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getList(
            @Parameter(description = "年度", example = "2025")
            @RequestParam(required = false) Integer year,
            @Parameter(description = "状态：UNPAID-未缴, PAID-已缴, PARTIAL-部分缴纳")
            @RequestParam(required = false) String status,
            @Parameter(description = "关键词（单位名称）")
            @RequestParam(required = false) String keyword,
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer pageNum,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return collectionService.getList(year, status, keyword, pageNum, pageSize);
    }

    @Operation(summary = "缴款核销", description = "对未缴或部分缴纳的记录进行核销")
    @PostMapping("/verify")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> verifyPayment(
            @Parameter(description = "征收记录ID", required = true)
            @RequestParam Long collectionId,
            @Parameter(description = "核销金额", required = true)
            @RequestParam Double amount,
            @Parameter(description = "凭证号")
            @RequestParam(required = false) String voucherNo,
            @Parameter(description = "核销备注")
            @RequestParam(required = false) String remark) {
        return collectionService.verifyPayment(collectionId, amount, voucherNo, remark);
    }

    @Operation(summary = "获取单位缴费记录", description = "获取指定单位的历年缴费记录")
    @GetMapping("/payment-records/{companyId}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getPaymentRecords(
            @Parameter(description = "单位ID", required = true, example = "1")
            @PathVariable Long companyId) {
        return collectionService.getPaymentRecords(companyId);
    }
}

package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.DisabledAuditService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

/**
 * 残疾人员工审核控制器
 */
@Tag(name = "残疾人员工审核", description = "残疾人员工信息的审核流程管理")
@RestController
@RequestMapping("/disabled-audit")
public class DisabledAuditController {

    @Resource
    private DisabledAuditService disabledAuditService;

    @Operation(summary = "查询审核列表", description = "根据公司、年度、审核状态等条件筛选审核记录")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getList(
            @Parameter(description = "公司ID", example = "1")
            @RequestParam(required = false) Long companyId,
            @Parameter(description = "年度", example = "2024")
            @RequestParam(required = false) Integer year,
            @Parameter(description = "审核状态：0-待审核，1-已通过，2-已拒绝", example = "0")
            @RequestParam(required = false) Integer auditStatus) {
        return disabledAuditService.getList(companyId, year, auditStatus);
    }

    @Operation(summary = "查询审核详情", description = "获取指定审核记录的详细信息")
    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getDetail(
            @Parameter(description = "审核记录ID", required = true, example = "1")
            @PathVariable Long id) {
        return disabledAuditService.getDetail(id);
    }

    @Operation(summary = "审核残疾人员工", description = "对提交的残疾人员工信息进行审核，设置审核状态")
    @PostMapping("/audit")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> audit(
            @Parameter(description = "审核记录ID", required = true, example = "1")
            @RequestParam Long id,
            @Parameter(description = "审核状态：1-通过，2-拒绝", required = true, example = "1")
            @RequestParam Integer status) {
        return disabledAuditService.audit(id, status);
    }
}


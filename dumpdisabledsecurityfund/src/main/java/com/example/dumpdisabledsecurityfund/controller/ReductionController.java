package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ReductionApplyDTO;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

/**
 * 减免申请控制器
 */
@Tag(name = "减免申请管理", description = "残保金减免申请的提交、审核和查询功能")
@RestController
@RequestMapping("/reduction")
public class ReductionController {

    @Resource
    private ReductionService reductionService;

    @Operation(summary = "提交减免申请", description = "企业用户提交残保金减免申请，包含申请类型、金额和理由")
    @PostMapping("/apply")
    @RequirePermission(roles = {"company_user"})
    public Result<?> apply(
            @Parameter(description = "减免申请信息", required = true)
            @Valid @RequestBody ReductionApplyDTO dto) {
        return reductionService.apply(dto);
    }

    @Operation(summary = "查询减免申请列表", description = "根据公司、年度、审核状态等条件筛选减免申请记录")
    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getList(
            @Parameter(description = "公司ID", example = "1")
            @RequestParam(required = false) Long companyId,
            @Parameter(description = "年度", example = "2024")
            @RequestParam(required = false) Integer year,
            @Parameter(description = "审核状态：0-待审核，1-已通过，2-已拒绝，3-已撤回", example = "0")
            @RequestParam(required = false) Integer auditStatus) {
        return reductionService.getList(companyId, year, auditStatus);
    }

    @Operation(summary = "查询减免申请详情", description = "获取指定减免申请的详细信息，包括审核意见")
    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getDetail(
            @Parameter(description = "申请ID", required = true, example = "1")
            @PathVariable Long id) {
        return reductionService.getDetail(id);
    }

    @Operation(summary = "审核减免申请", description = "管理员对减免申请进行审核，设置审核状态和审核意见")
    @PostMapping("/audit")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> audit(
            @Parameter(description = "申请ID", required = true, example = "1")
            @RequestParam Long id,
            @Parameter(description = "审核状态：1-通过，2-拒绝", required = true, example = "1")
            @RequestParam Integer auditStatus,
            @Parameter(description = "审核意见", example = "同意减免")
            @RequestParam(required = false) String auditOpinion) {
        return reductionService.audit(id, auditStatus, auditOpinion);
    }

    @Operation(summary = "撤回减免申请", description = "企业用户撤回已提交但尚未审核的减免申请")
    @DeleteMapping("/withdraw/{id}")
    @RequirePermission(roles = {"company_user"})
    public Result<?> withdraw(
            @Parameter(description = "申请ID", required = true, example = "1")
            @PathVariable Long id) {
        return reductionService.withdraw(id);
    }
}


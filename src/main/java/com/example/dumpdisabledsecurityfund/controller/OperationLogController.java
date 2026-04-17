package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.OperationLogService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

/**
 * 操作日志控制器
 */
@Tag(name = "操作日志管理", description = "系统操作日志的查询和清理功能")
@RestController
@RequestMapping("/operation-log")
public class OperationLogController {

    @Resource
    private OperationLogService operationLogService;

    @Operation(summary = "查询我的操作日志", description = "获取登录用户自己的操作记录，支持分页查询")
    @GetMapping("/my-logs")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getMyLogs(
            @Parameter(description = "页码，默认第1页", example = "1")
            @RequestParam(required = false) Integer pageNum,
            @Parameter(description = "每页条数，默认10条", example = "10")
            @RequestParam(required = false) Integer pageSize) {
        return operationLogService.getLogsByUserId(null, pageNum, pageSize);
    }

    @Operation(summary = "查询所有操作日志", description = "获取系统中所有的操作记录，支持分页查询")
    @GetMapping("/all")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> getAllLogs(
            @Parameter(description = "页码，默认第1页", example = "1")
            @RequestParam(required = false) Integer pageNum,
            @Parameter(description = "每页条数，默认10条", example = "10")
            @RequestParam(required = false) Integer pageSize) {
        return operationLogService.getAllLogs(pageNum, pageSize);
    }

    @Operation(summary = "查询最近操作日志", description = "获取最近N条操作记录，用于首页展示或实时监控")
    @GetMapping("/recent")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getRecentLogs(
            @Parameter(description = "限制条数，默认10条", example = "10")
            @RequestParam(required = false) Integer limit) {
        return operationLogService.getRecentLogs(limit);
    }

    @Operation(summary = "清理历史操作日志", description = "删除指定日期之前的操作日志记录，用于数据维护")
    @DeleteMapping("/clean")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> deleteOldLogs(
            @Parameter(description = "删除此日期之前的日志，格式：yyyy-MM-dd", required = true, example = "2024-01-01")
            @RequestParam String beforeDate) {
        return operationLogService.deleteOldLogs(beforeDate);
    }
}

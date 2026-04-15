package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.OperationLogService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/operation-log")
public class OperationLogController {

    @Resource
    private OperationLogService operationLogService;

    @GetMapping("/my-logs")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getMyLogs(@RequestParam(required = false) Integer pageNum,
                               @RequestParam(required = false) Integer pageSize) {
        return operationLogService.getLogsByUserId(null, pageNum, pageSize);
    }

    @GetMapping("/all")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> getAllLogs(@RequestParam(required = false) Integer pageNum,
                                @RequestParam(required = false) Integer pageSize) {
        return operationLogService.getAllLogs(pageNum, pageSize);
    }

    @GetMapping("/recent")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getRecentLogs(@RequestParam(required = false) Integer limit) {
        return operationLogService.getRecentLogs(limit);
    }

    @DeleteMapping("/clean")
    @RequirePermission(roles = {"admin_system"})
    public Result<?> deleteOldLogs(@RequestParam String beforeDate) {
        return operationLogService.deleteOldLogs(beforeDate);
    }
}

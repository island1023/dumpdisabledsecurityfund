package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.DisabledAuditService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/disabled-audit")
public class DisabledAuditController {

    @Resource
    private DisabledAuditService disabledAuditService;

    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getList(@RequestParam(required = false) Long companyId,
                             @RequestParam(required = false) Integer year,
                             @RequestParam(required = false) Integer auditStatus) {
        return disabledAuditService.getList(companyId, year, auditStatus);
    }

    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> getDetail(@PathVariable Long id) {
        return disabledAuditService.getDetail(id);
    }

    @PostMapping("/audit")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> audit(@RequestParam Long id, @RequestParam Integer status) {
        return disabledAuditService.audit(id, status);
    }
}

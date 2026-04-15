package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.ReportService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/report")
public class ReportController {
    @Resource
    private ReportService reportService;

    @GetMapping("/statistics")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public Result<?> statistics(@RequestParam(required = false) Integer year) {
        return reportService.getStatistics(year);
    }
}

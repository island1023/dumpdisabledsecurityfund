package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.FundUsageService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@RestController
@RequestMapping("/fundUsage")
public class FundUsageController {
    @Resource
    private FundUsageService fundUsageService;

    @PostMapping("/importExcel")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> importExcel(MultipartFile file) {
        return fundUsageService.importExcel(file);
    }
}

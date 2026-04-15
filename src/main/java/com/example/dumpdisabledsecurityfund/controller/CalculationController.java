package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.CalculationRuleService;
import com.example.dumpdisabledsecurityfund.service.CalculationService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/calculation")
public class CalculationController {

    @Resource
    private CalculationService calculationService;

    @Resource
    private CalculationRuleService calculationRuleService;

    @GetMapping("/calculate")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> calculate(@RequestParam Long companyId, @RequestParam Integer year) {
        return calculationRuleService.calculateWithRule(companyId, year);
    }
}

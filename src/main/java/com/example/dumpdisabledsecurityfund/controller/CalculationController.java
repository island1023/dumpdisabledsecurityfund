package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.CalculationRuleService;
import com.example.dumpdisabledsecurityfund.service.CalculationService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

/**
 * 保障金计算控制器
 */
@Tag(name = "残保金计算", description = "残保金应缴金额计算功能")
@RestController
@RequestMapping("/calculation")
public class CalculationController {

    @Resource
    private CalculationService calculationService;

    @Resource
    private CalculationRuleService calculationRuleService;

    @Operation(summary = "计算残保金", description = "根据公司ID和年度，使用当前启用的计算规则进行残保金计算")
    @GetMapping("/calculate")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> calculate(
            @Parameter(description = "公司ID", required = true, example = "1")
            @RequestParam Long companyId,
            @Parameter(description = "计算年度", required = true, example = "2024")
            @RequestParam Integer year) {
        return calculationRuleService.calculateWithRule(companyId, year);
    }
}


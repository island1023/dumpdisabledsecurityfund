package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CalculationRule;
import com.example.dumpdisabledsecurityfund.service.CalculationRuleService;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/calculation-rule")
public class CalculationRuleController {

    @Resource
    private CalculationRuleService calculationRuleService;

    @PostMapping("/create")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> createRule(@RequestBody CalculationRule rule) {
        return calculationRuleService.createRule(rule);
    }

    @PutMapping("/update")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> updateRule(@RequestBody CalculationRule rule) {
        return calculationRuleService.updateRule(rule);
    }

    @DeleteMapping("/delete/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> deleteRule(@PathVariable Long id) {
        return calculationRuleService.deleteRule(id);
    }

    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public Result<?> getRuleById(@PathVariable Long id) {
        return calculationRuleService.getRuleById(id);
    }

    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader"})
    public Result<?> getAllRules() {
        return calculationRuleService.getAllRules();
    }

    @GetMapping("/active/{year}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "leader", "company_user"})
    public Result<?> getActiveRuleByYear(@PathVariable Integer year) {
        return calculationRuleService.getActiveRuleByYear(year);
    }

    @PostMapping("/activate")
    @RequirePermission(roles = {"admin_system", "admin_city"})
    public Result<?> activateRule(@RequestParam Long id, @RequestParam Integer year) {
        return calculationRuleService.activateRule(id, year);
    }
}


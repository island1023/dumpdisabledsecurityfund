package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CalculationRule;

import java.util.List;

public interface CalculationRuleService {

    Result<?> createRule(CalculationRule rule);

    Result<?> updateRule(CalculationRule rule);

    Result<?> deleteRule(Long id);

    Result<?> getRuleById(Long id);

    Result<?> getAllRules();

    Result<?> getActiveRuleByYear(Integer year);

    Result<?> activateRule(Long id, Integer year);

    Result<?> calculateWithRule(Long companyId, Integer year);
}

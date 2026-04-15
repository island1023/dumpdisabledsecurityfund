package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CalculationRule;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.mapper.CalculationRuleMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.CalculationRuleService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CalculationRuleServiceImpl implements CalculationRuleService {

    @Resource
    private CalculationRuleMapper calculationRuleMapper;

    @Resource
    private CompanyEmployeeMapper companyEmployeeMapper;

    @Resource
    private CompanyDisabledEmployeeMapper companyDisabledEmployeeMapper;

    @Resource
    private PayableAmountMapper payableAmountMapper;

    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final double DEFAULT_PENALTY_PER_SHORTAGE = 5000D;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "创建计算规则", table = "calculation_rule")
    public Result<?> createRule(CalculationRule rule) {
        if (rule.getApplyYear() == null || rule.getRequiredRatio() == null) {
            return Result.error("适用年度和应安置比例不能为空");
        }

        CalculationRule existing = calculationRuleMapper.selectActiveByYear(rule.getApplyYear());
        if (existing != null && rule.getIsActive() == 1) {
            return Result.error(rule.getApplyYear() + "年度已存在启用的规则");
        }

        rule.setCreateTime(DateUtil.now());
        rule.setUpdateTime(DateUtil.now());

        if (rule.getIsActive() == null) {
            rule.setIsActive(0);
        }

        calculationRuleMapper.insert(rule);
        return Result.success("规则创建成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "更新计算规则", table = "calculation_rule")
    public Result<?> updateRule(CalculationRule rule) {
        if (rule.getId() == null) {
            return Result.error("规则ID不能为空");
        }

        rule.setUpdateTime(DateUtil.now());
        calculationRuleMapper.updateById(rule);
        return Result.success("规则更新成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "删除计算规则", table = "calculation_rule")
    public Result<?> deleteRule(Long id) {
        if (id == null) {
            return Result.error("规则ID不能为空");
        }

        calculationRuleMapper.deleteById(id);
        return Result.success("规则删除成功");
    }

    @Override
    public Result<?> getRuleById(Long id) {
        CalculationRule rule = calculationRuleMapper.selectById(id);
        if (rule == null) {
            return Result.error("规则不存在");
        }
        return Result.success(rule);
    }

    @Override
    public Result<?> getAllRules() {
        List<CalculationRule> rules = calculationRuleMapper.selectAll();
        return Result.success(rules);
    }

    @Override
    public Result<?> getActiveRuleByYear(Integer year) {
        if (year == null) {
            return Result.error("年度不能为空");
        }

        CalculationRule rule = calculationRuleMapper.selectActiveByYear(year);
        if (rule == null) {
            return Result.error(year + "年度未配置计算规则");
        }
        return Result.success(rule);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "激活计算规则", table = "calculation_rule")
    public Result<?> activateRule(Long id, Integer year) {
        if (id == null || year == null) {
            return Result.error("参数不能为空");
        }

        calculationRuleMapper.deactivateByYear(year);

        CalculationRule rule = new CalculationRule();
        rule.setId(id);
        rule.setIsActive(1);
        rule.setUpdateTime(DateUtil.now());
        calculationRuleMapper.updateById(rule);

        return Result.success("规则激活成功");
    }

    @Override
    @LogOperation(value = "计算应缴金额", table = "payable_amount")
    public Result<?> calculateWithRule(Long companyId, Integer year) {
        if (companyId == null || year == null) {
            return Result.error("公司ID和年度不能为空");
        }

        CalculationRule rule = calculationRuleMapper.selectActiveByYear(year);
        if (rule == null) {
            return Result.error(year + "年度未配置计算规则，请先配置规则");
        }

        int totalEmployees = companyEmployeeMapper.countActiveByCompanyId(companyId);
        int disabledEmployees = companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);

        double requiredRatio = rule.getRequiredRatio();
        int shouldDisabled = (int) Math.ceil(totalEmployees * requiredRatio / 100D);
        int shortage = Math.max(0, shouldDisabled - disabledEmployees);

        double amount = calculateAmount(rule, shortage, totalEmployees);

        PayableAmount db = payableAmountMapper.selectByCompanyAndYear(companyId, year);
        if (db == null) {
            PayableAmount insert = new PayableAmount();
            insert.setCompanyId(companyId);
            insert.setYear(year);
            insert.setTotalEmployeeCount(totalEmployees);
            insert.setDisabledEmployeeCount(disabledEmployees);
            insert.setRequiredRatio(requiredRatio);
            insert.setCalculatedAmount(amount);
            insert.setStatus(0);
            payableAmountMapper.insert(insert);
        } else {
            db.setTotalEmployeeCount(totalEmployees);
            db.setDisabledEmployeeCount(disabledEmployees);
            db.setRequiredRatio(requiredRatio);
            db.setCalculatedAmount(amount);
            db.setStatus(0);
            db.setConfirmTime(DateUtil.now());
            payableAmountMapper.updateById(db);
        }

        Map<String, Object> result = new HashMap<>();
        result.put("companyId", companyId);
        result.put("year", year);
        result.put("ruleName", rule.getRuleName());
        result.put("totalEmployeeCount", totalEmployees);
        result.put("disabledEmployeeCount", disabledEmployees);
        result.put("requiredRatio", requiredRatio);
        result.put("requiredDisabledCount", shouldDisabled);
        result.put("shortageCount", shortage);
        result.put("calculatedAmount", amount);
        return Result.success(result);
    }

    private double calculateAmount(CalculationRule rule, int shortage, int totalEmployees) {
        try {
            if (rule.getFormulaJson() != null && !rule.getFormulaJson().isEmpty()) {
                JsonNode formula = objectMapper.readTree(rule.getFormulaJson());

                String type = formula.has("type") ? formula.get("type").asText() : "simple";

                if ("simple".equals(type)) {
                    double unitPrice = formula.has("unitPrice") ? formula.get("unitPrice").asDouble() : DEFAULT_PENALTY_PER_SHORTAGE;
                    return shortage * unitPrice;
                } else if ("tiered".equals(type)) {
                    return calculateTieredAmount(formula, shortage);
                } else if ("percentage".equals(type)) {
                    double baseSalary = formula.has("baseSalary") ? formula.get("baseSalary").asDouble() : 60000;
                    return shortage * baseSalary;
                }
            }
        } catch (Exception e) {
            return shortage * DEFAULT_PENALTY_PER_SHORTAGE;
        }

        return shortage * DEFAULT_PENALTY_PER_SHORTAGE;
    }

    private double calculateTieredAmount(JsonNode formula, int shortage) {
        JsonNode tiers = formula.get("tiers");
        if (tiers == null || !tiers.isArray()) {
            return shortage * DEFAULT_PENALTY_PER_SHORTAGE;
        }

        double totalAmount = 0;
        int remaining = shortage;

        for (JsonNode tier : tiers) {
            int maxCount = tier.has("maxCount") ? tier.get("maxCount").asInt() : Integer.MAX_VALUE;
            double price = tier.has("price") ? tier.get("price").asDouble() : DEFAULT_PENALTY_PER_SHORTAGE;

            int count = Math.min(remaining, maxCount);
            totalAmount += count * price;
            remaining -= count;

            if (remaining <= 0) {
                break;
            }
        }

        if (remaining > 0) {
            double defaultPrice = formula.has("defaultPrice") ? formula.get("defaultPrice").asDouble() : DEFAULT_PENALTY_PER_SHORTAGE;
            totalAmount += remaining * defaultPrice;
        }

        return totalAmount;
    }
}

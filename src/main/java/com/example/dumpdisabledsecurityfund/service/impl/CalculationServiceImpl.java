package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.mapper.CalculationRuleMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.CalculationService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.Map;

@Service
public class CalculationServiceImpl implements CalculationService {
    private static final double DEFAULT_REQUIRED_RATIO = 1.5D;
    private static final double DEFAULT_PENALTY_PER_SHORTAGE = 5000D;

    @Resource
    private CompanyEmployeeMapper companyEmployeeMapper;
    @Resource
    private CompanyDisabledEmployeeMapper companyDisabledEmployeeMapper;
    @Resource
    private PayableAmountMapper payableAmountMapper;
    @Resource
    private CalculationRuleMapper calculationRuleMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> calculate(Long companyId, Integer year) {
        if (companyId == null || year == null) {
            return Result.error("公司ID和年度不能为空");
        }

        long totalEmployeesLong = companyEmployeeMapper.countActiveByCompanyId(companyId);
        long disabledEmployeesLong = companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);

        int totalEmployees = (int) totalEmployeesLong;
        int disabledEmployees = (int) disabledEmployeesLong;

        Double ratio = calculationRuleMapper.selectActiveRatioByYear(year);
        double requiredRatio = ratio != null ? ratio : DEFAULT_REQUIRED_RATIO;

        int shouldDisabled = (int) Math.ceil(totalEmployees * requiredRatio / 100D);
        int shortage = Math.max(0, shouldDisabled - disabledEmployees);
        double amount = shortage * DEFAULT_PENALTY_PER_SHORTAGE;

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
            insert.setConfirmTime(null);
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
        result.put("totalEmployeeCount", totalEmployees);
        result.put("disabledEmployeeCount", disabledEmployees);
        result.put("requiredRatio", requiredRatio);
        result.put("requiredDisabledCount", shouldDisabled);
        result.put("shortageCount", shortage);
        result.put("calculatedAmount", amount);
        return Result.success(result);
    }
}

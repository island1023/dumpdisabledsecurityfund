package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyReductionMapper;
import com.example.dumpdisabledsecurityfund.mapper.FundUsageMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.ReportService;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.time.Year;
import java.util.HashMap;
import java.util.Map;

@Service
public class ReportServiceImpl implements ReportService {
    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private PayableAmountMapper payableAmountMapper;
    @Resource
    private CompanyReductionMapper companyReductionMapper;
    @Resource
    private FundUsageMapper fundUsageMapper;

    @Override
    public Result<?> getStatistics(Integer year) {
        int actualYear = year == null ? Year.now().getValue() : year;

        Map<String, Object> map = new HashMap<>();
        map.put("year", actualYear);
        map.put("totalCompany", companyMapper.countAll());
        map.put("totalPayableFund", payableAmountMapper.sumCalculatedAmountByYear(actualYear));
        map.put("paidCompany", payableAmountMapper.countByStatusAndYear(actualYear, 1));
        map.put("unpaidCompany", payableAmountMapper.countByStatusAndYear(actualYear, 0));
        map.put("reductionApplyAmount", companyReductionMapper.sumApplyAmountByYear(actualYear));
        map.put("fundUsageAmount", fundUsageMapper.sumAmountByYear(actualYear));
        return Result.success(map);
    }
}

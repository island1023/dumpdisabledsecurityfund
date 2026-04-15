package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

public interface CalculationService {
    Result<?> calculate(Long companyId, Integer year);
}

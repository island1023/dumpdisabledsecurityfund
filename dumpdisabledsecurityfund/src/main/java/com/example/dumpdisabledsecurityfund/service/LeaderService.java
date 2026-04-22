package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

public interface LeaderService {
    Result<?> listArchiveCompanies(String keyword, Integer pageNum, Integer pageSize);

    Result<?> getArchiveCompanyDetail(Long companyId);

    Result<?> listFundUsage(String keyword, String projectType);

    Result<?> listExternalReportRows(String reportType, Integer year, Integer month);
}

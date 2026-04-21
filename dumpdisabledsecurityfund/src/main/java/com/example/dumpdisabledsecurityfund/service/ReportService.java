package com.example.dumpdisabledsecurityfund.service;
import com.example.dumpdisabledsecurityfund.common.Result;

public interface ReportService {
    Result<?> getStatistics(Integer year);
}
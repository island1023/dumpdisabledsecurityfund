package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import org.springframework.web.multipart.MultipartFile;

public interface CompanyService {
    Result<?> importExcel(MultipartFile file);

    Result<?> list(String keyword, Integer pageNum, Integer pageSize);

    Result<?> getDetail(Long id);

    Result<?> getCurrentCompanyInfo();
}

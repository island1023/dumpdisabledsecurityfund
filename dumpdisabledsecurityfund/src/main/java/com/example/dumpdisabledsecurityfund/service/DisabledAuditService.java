package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

public interface DisabledAuditService {

    Result<?> getList(Long companyId, Integer year, Integer auditStatus);

    Result<?> getDetail(Long id);

    Result<?> audit(Long id, Integer status);
}

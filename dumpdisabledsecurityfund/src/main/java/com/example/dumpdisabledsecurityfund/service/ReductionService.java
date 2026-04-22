package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ReductionApplyDTO;

public interface ReductionService {
    Result<?> apply(ReductionApplyDTO dto);

    Result<?> getList(Long companyId, Integer year, Integer auditStatus);

    Result<?> getDetail(Long id);

    Result<?> audit(Long id, Integer auditStatus, String auditOpinion);

    Result<?> withdraw(Long id);

    Result<?> submitApplication(Object request);

    Result<?> getApplications(Integer page, Integer pageSize);

    Result<?> getApplicationDetail(Long applicationId);

    Result<?> getApplicationProgress();
}

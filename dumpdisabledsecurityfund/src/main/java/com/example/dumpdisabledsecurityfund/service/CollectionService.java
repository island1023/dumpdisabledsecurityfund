package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

public interface CollectionService {
    
    /**
     * 获取征收统计
     */
    Result<?> getStatistics(Integer year);
    
    /**
     * 获取征收列表
     */
    Result<?> getList(Integer year, String status, String keyword, Integer pageNum, Integer pageSize);
    
    /**
     * 缴款核销
     */
    Result<?> verifyPayment(Long collectionId, Double amount, String voucherNo, String remark);
    
    /**
     * 获取单位缴费记录
     */
    Result<?> getPaymentRecords(Long companyId);
}

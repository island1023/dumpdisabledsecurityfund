package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

/**
 * 审批服务接口
 */
public interface ApprovalService {

    /**
     * 获取待审批列表
     */
    Result<?> getPendingList(Integer page, Integer pageSize, String type, Long regionId);

    /**
     * 审批通过
     */
    Result<?> approve(String approvalId);

    /**
     * 审批驳回
     */
    Result<?> reject(String approvalId, String reason);

    /**
     * 获取审批详情
     */
    Result<?> getDetail(String approvalId);

    /**
     * 获取审批统计
     */
    Result<?> getStatistics();
}

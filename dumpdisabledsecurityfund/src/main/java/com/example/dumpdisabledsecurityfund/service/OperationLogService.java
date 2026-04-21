package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;

public interface OperationLogService {

    void logOperation(Long userId, String operationType, String targetTable,
                      Long targetId, String detail, String ipAddress);

    Result<?> getLogsByUserId(Long userId, Integer pageNum, Integer pageSize);

    Result<?> getAllLogs(Integer pageNum, Integer pageSize);

    Result<?> getRecentLogs(Integer limit);

    Result<?> deleteOldLogs(String beforeDate);
}

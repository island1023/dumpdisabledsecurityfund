package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.OperationLog;
import com.example.dumpdisabledsecurityfund.mapper.OperationLogMapper;
import com.example.dumpdisabledsecurityfund.service.OperationLogService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class OperationLogServiceImpl implements OperationLogService {

    @Resource
    private OperationLogMapper operationLogMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void logOperation(Long userId, String operationType, String targetTable,
                             Long targetId, String detail, String ipAddress) {
        if (userId == null) {
            return;
        }

        OperationLog log = new OperationLog();
        log.setUserId(userId);
        log.setOperationType(operationType);
        log.setTargetTable(targetTable);
        log.setTargetId(targetId);
        log.setDetail(detail);
        log.setIpAddress(ipAddress);
        log.setCreateTime(DateUtil.now());

        operationLogMapper.insert(log);
    }

    @Override
    public Result<?> getLogsByUserId(Long userId, Integer pageNum, Integer pageSize) {
        if (userId == null) {
            return Result.error("用户ID不能为空");
        }

        if (pageNum == null || pageNum < 1) {
            pageNum = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 10;
        }

        int total = operationLogMapper.countByUserId(userId);
        List<OperationLog> logs = operationLogMapper.selectByUserId(userId);

        PageResult<OperationLog> pageResult = PageResult.build(total, pageNum, pageSize, logs);

        return Result.success(pageResult);
    }

    @Override
    public Result<?> getAllLogs(Integer pageNum, Integer pageSize) {
        if (pageNum == null || pageNum < 1) {
            pageNum = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 10;
        }

        List<OperationLog> logs = operationLogMapper.selectRecentLogs(pageSize);

        PageResult<OperationLog> pageResult = PageResult.build(logs.size(), pageNum, pageSize, logs);

        return Result.success(pageResult);
    }

    @Override
    public Result<?> getRecentLogs(Integer limit) {
        if (limit == null || limit < 1) {
            limit = 10;
        }
        if (limit > 100) {
            limit = 100;
        }

        List<OperationLog> logs = operationLogMapper.selectRecentLogs(limit);
        return Result.success(logs);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> deleteOldLogs(String beforeDate) {
        if (beforeDate == null || beforeDate.isEmpty()) {
            return Result.error("日期不能为空");
        }

        int count = operationLogMapper.deleteBeforeDate(beforeDate);

        return Result.success("删除了 " + count + " 条旧日志");
    }
}

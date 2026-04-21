package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.DisabledAudit;
import com.example.dumpdisabledsecurityfund.mapper.DisabledAuditMapper;
import com.example.dumpdisabledsecurityfund.service.DisabledAuditService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DisabledAuditServiceImpl implements DisabledAuditService {

    @Resource
    private DisabledAuditMapper disabledAuditMapper;

    @Override
    public Result<?> getList(Long companyId, Integer year, Integer auditStatus) {
        List<DisabledAudit> list;

        if (companyId != null) {
            if (year != null) {
                list = disabledAuditMapper.selectByCompanyIdAndYear(companyId, year);
            } else {
                list = disabledAuditMapper.selectByCompanyId(companyId);
            }
        } else if (auditStatus != null) {
            list = disabledAuditMapper.selectByAuditStatus(auditStatus);
        } else {
            list = disabledAuditMapper.selectByAuditStatus(null);
        }

        return Result.success(list);
    }

    @Override
    public Result<?> getDetail(Long id) {
        if (id == null) {
            return Result.error("ID不能为空");
        }

        DisabledAudit audit = disabledAuditMapper.selectById(id);
        if (audit == null) {
            return Result.error("审核记录不存在");
        }

        return Result.success(audit);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> audit(Long id, Integer status) {
        if (id == null || status == null) {
            return Result.error("参数不完整");
        }

        if (status != 1 && status != 2) {
            return Result.error("审核状态错误：1-通过，2-不通过");
        }

        DisabledAudit existing = disabledAuditMapper.selectById(id);
        if (existing == null) {
            return Result.error("审核记录不存在");
        }

        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        Long auditorId = null;
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();
            Object userId = request.getAttribute("userId");
            if (userId != null) {
                auditorId = Long.valueOf(userId.toString());
            }
        }

        String auditTime = DateUtil.now();
        int rows = disabledAuditMapper.updateStatusById(id, status, auditorId, auditTime);

        if (rows == 0) {
            return Result.error("审核失败");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", id);
        result.put("status", status);
        result.put("auditTime", auditTime);
        result.put("message", status == 1 ? "审核通过" : "审核不通过");

        return Result.success(result);
    }
}

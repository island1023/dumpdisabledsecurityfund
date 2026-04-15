package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ReductionApplyDTO;
import com.example.dumpdisabledsecurityfund.entity.CompanyReduction;
import com.example.dumpdisabledsecurityfund.mapper.CompanyReductionMapper;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
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
public class ReductionServiceImpl implements ReductionService {

    @Resource
    private CompanyReductionMapper companyReductionMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "提交减免申请", table = "company_reduction")
    public Result<?> apply(ReductionApplyDTO dto) {
        if (dto.getCompanyId() == null || dto.getYear() == null || dto.getApplyType() == null) {
            return Result.error("参数不完整");
        }

        if (dto.getApplyType() < 1 || dto.getApplyType() > 3) {
            return Result.error("申请类型错误：1-减，2-免，3-缓");
        }

        CompanyReduction reduction = new CompanyReduction();
        reduction.setCompanyId(dto.getCompanyId());
        reduction.setYear(dto.getYear());
        reduction.setApplyType(dto.getApplyType());
        reduction.setApplyAmount(dto.getApplyAmount() != null ? dto.getApplyAmount() : 0D);
        reduction.setReason(dto.getReason());
        reduction.setAuditStatus(0);
        reduction.setCreateTime(DateUtil.now());
        reduction.setUpdateTime(DateUtil.now());

        companyReductionMapper.insert(reduction);

        Map<String, Object> result = new HashMap<>();
        result.put("id", reduction.getId());
        result.put("message", "申请提交成功，等待审核");

        return Result.success(result);
    }

    @Override
    public Result<?> getList(Long companyId, Integer year, Integer auditStatus) {
        List<CompanyReduction> list;

        if (companyId != null) {
            if (year != null) {
                list = companyReductionMapper.selectByCompanyIdAndYear(companyId, year);
            } else {
                list = companyReductionMapper.selectByCompanyId(companyId);
            }
        } else if (auditStatus != null) {
            list = companyReductionMapper.selectByAuditStatus(auditStatus);
        } else {
            list = companyReductionMapper.selectByAuditStatus(null);
        }

        return Result.success(list);
    }

    @Override
    public Result<?> getDetail(Long id) {
        if (id == null) {
            return Result.error("ID不能为空");
        }

        CompanyReduction reduction = companyReductionMapper.selectById(id);
        if (reduction == null) {
            return Result.error("申请记录不存在");
        }

        return Result.success(reduction);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "审核减免申请", table = "company_reduction")
    public Result<?> audit(Long id, Integer auditStatus, String auditOpinion) {
        if (id == null || auditStatus == null) {
            return Result.error("参数不完整");
        }

        if (auditStatus != 1 && auditStatus != 2) {
            return Result.error("审核状态错误：1-通过，2-驳回");
        }

        CompanyReduction existing = companyReductionMapper.selectById(id);
        if (existing == null) {
            return Result.error("申请记录不存在");
        }

        if (existing.getAuditStatus() != 0) {
            return Result.error("该申请已审核，无法重复操作");
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

        String updateTime = DateUtil.now();
        int rows = companyReductionMapper.updateAuditStatus(
                id,
                auditStatus,
                auditorId,
                auditOpinion,
                updateTime,
                updateTime
        );

        if (rows == 0) {
            return Result.error("审核失败");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", id);
        result.put("auditStatus", auditStatus);
        result.put("auditTime", updateTime);
        result.put("message", auditStatus == 1 ? "审核通过" : "审核驳回");

        return Result.success(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "撤回减免申请", table = "company_reduction")
    public Result<?> withdraw(Long id) {
        if (id == null) {
            return Result.error("ID不能为空");
        }

        CompanyReduction existing = companyReductionMapper.selectById(id);
        if (existing == null) {
            return Result.error("申请记录不存在");
        }

        if (existing.getAuditStatus() != 0) {
            return Result.error("该申请已审核，无法撤回");
        }

        companyReductionMapper.deleteById(id);

        return Result.success("申请已撤回");
    }
}

package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ReductionApplyDTO;
import com.example.dumpdisabledsecurityfund.entity.CompanyReduction;
import com.example.dumpdisabledsecurityfund.mapper.CompanyReductionMapper;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.vo.ApplicationProgressVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.*;
import java.util.stream.Collectors;

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
        reduction.setAttachment(dto.getAttachment());
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
    public Result<?> submitApplication(Object request) {
        if (!(request instanceof Map)) {
            return Result.error("请求参数格式错误");
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> reqMap = (Map<String, Object>) request;

        ReductionApplyDTO dto = new ReductionApplyDTO();
        dto.setCompanyId(getCurrentCompanyId());
        dto.setYear(Integer.parseInt(reqMap.get("year").toString().replace("年", "")));
        dto.setApplyType(parseApplyType(String.valueOf(reqMap.get("type"))));
        dto.setApplyAmount(Double.parseDouble(reqMap.get("amount").toString()));
        dto.setReason((String) reqMap.get("reason"));
        dto.setAttachment((String) reqMap.get("attachment"));

        return apply(dto);
    }

    @Override
    public Result<?> getApplications(Integer page, Integer pageSize) {
        if (page == null || page < 1) page = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<CompanyReduction> allList = companyReductionMapper.selectByCompanyId(companyId);
        long total = allList.size();

        int fromIndex = (page - 1) * pageSize;
        int toIndex = Math.min(fromIndex + pageSize, allList.size());

        List<CompanyReduction> pageList = fromIndex < allList.size() ?
                allList.subList(fromIndex, toIndex) : new ArrayList<>();

        List<Map<String, Object>> result = pageList.stream().map(item -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", item.getId());
            map.put("type", getApplyTypeName(item.getApplyType()));
            map.put("year", item.getYear() + "年");
            map.put("amount", "¥" + String.format("%,.0f", item.getApplyAmount()));
            map.put("status", getAuditStatusName(item.getAuditStatus()));
            map.put("date", item.getCreateTime());
            return map;
        }).collect(Collectors.toList());

        Map<String, Object> data = new HashMap<>();
        data.put("total", total);
        data.put("list", result);

        return Result.success(data);
    }

    @Override
    public Result<?> getApplicationDetail(Long applicationId) {
        CompanyReduction reduction = companyReductionMapper.selectById(applicationId);
        if (reduction == null) {
            return Result.error("申请记录不存在");
        }

        Map<String, Object> result = new HashMap<>();
        result.put("id", reduction.getId());
        result.put("type", getApplyTypeName(reduction.getApplyType()));
        result.put("year", reduction.getYear() + "年");
        result.put("amount", String.valueOf(reduction.getApplyAmount()));
        result.put("reason", reduction.getReason());
        result.put("attachment", reduction.getAttachment());
        result.put("status", getAuditStatusName(reduction.getAuditStatus()));
        result.put("submitDate", reduction.getCreateTime());

        return Result.success(result);
    }

    @Override
    public Result<?> getApplicationProgress() {
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<CompanyReduction> reductions = companyReductionMapper.selectByCompanyId(companyId);

        if (reductions.isEmpty()) {
            return Result.error("暂无申请记录");
        }

        CompanyReduction latest = reductions.get(0);

        ApplicationProgressVO vo = new ApplicationProgressVO();

        List<ApplicationProgressVO.ProgressStep> steps = new ArrayList<>();

        ApplicationProgressVO.ProgressStep step1 = new ApplicationProgressVO.ProgressStep();
        step1.setTitle("填写申报表");
        step1.setStatus("completed");
        step1.setTime(latest.getCreateTime());
        steps.add(step1);

        ApplicationProgressVO.ProgressStep step2 = new ApplicationProgressVO.ProgressStep();
        step2.setTitle("上传证明材料");
        step2.setStatus("completed");
        step2.setTime(latest.getCreateTime());
        steps.add(step2);

        ApplicationProgressVO.ProgressStep step3 = new ApplicationProgressVO.ProgressStep();
        step3.setTitle("提交审核");
        step3.setStatus("completed");
        step3.setTime(latest.getCreateTime());
        steps.add(step3);

        if (latest.getAuditStatus() == 0) {
            ApplicationProgressVO.ProgressStep step4 = new ApplicationProgressVO.ProgressStep();
            step4.setTitle("区级审核");
            step4.setStatus("current");
            step4.setTime("");
            steps.add(step4);

            vo.setCurrentStep("区级审核");
            vo.setMessage("当前正在等待区级审核，预计3-5个工作日完成");
        } else if (latest.getAuditStatus() == 1) {
            ApplicationProgressVO.ProgressStep step4 = new ApplicationProgressVO.ProgressStep();
            step4.setTitle("区级审核");
            step4.setStatus("completed");
            step4.setTime(latest.getAuditTime());
            steps.add(step4);

            ApplicationProgressVO.ProgressStep step5 = new ApplicationProgressVO.ProgressStep();
            step5.setTitle("审核完成");
            step5.setStatus("completed");
            step5.setTime(latest.getAuditTime());
            steps.add(step5);

            vo.setCurrentStep("审核完成");
            vo.setMessage("申请已通过审核");
        } else {
            ApplicationProgressVO.ProgressStep step4 = new ApplicationProgressVO.ProgressStep();
            step4.setTitle("区级审核");
            step4.setStatus("completed");
            step4.setTime(latest.getAuditTime());
            steps.add(step4);

            vo.setCurrentStep("审核驳回");
            vo.setMessage("申请已被驳回：" + latest.getAuditOpinion());
        }

        vo.setSteps(steps);

        return Result.success(vo);
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

    private Long getCurrentCompanyId() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }

        HttpServletRequest request = attributes.getRequest();
        Object companyIdObj = request.getAttribute("companyId");

        if (companyIdObj == null) {
            return null;
        }

        return Long.valueOf(companyIdObj.toString());
    }

    private String getAuditStatusName(Integer status) {
        if (status == null) return "待审核";
        switch (status) {
            case 0: return "审批中";
            case 1: return "已通过";
            case 2: return "已驳回";
            case 3: return "已撤回";
            default: return "未知";
        }
    }

    private Integer parseApplyType(String type) {
        if (type == null) {
            return 1;
        }
        String value = type.trim();
        if ("减".equals(value) || "减免".equals(value)) {
            return 1;
        }
        if ("免".equals(value) || "免缴".equals(value)) {
            return 2;
        }
        if ("缓".equals(value) || "缓缴".equals(value)) {
            return 3;
        }
        return 1;
    }

    private String getApplyTypeName(Integer applyType) {
        if (applyType == null) {
            return "减";
        }
        switch (applyType) {
            case 1: return "减";
            case 2: return "免";
            case 3: return "缓";
            default: return "减";
        }
    }
}

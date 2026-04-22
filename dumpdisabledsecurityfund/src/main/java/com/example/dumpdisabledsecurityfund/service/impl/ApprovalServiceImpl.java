package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.CompanyReduction;
import com.example.dumpdisabledsecurityfund.entity.DisabledAudit;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyReductionMapper;
import com.example.dumpdisabledsecurityfund.mapper.DisabledAuditMapper;
import com.example.dumpdisabledsecurityfund.service.ApprovalService;
import com.example.dumpdisabledsecurityfund.service.DisabledAuditService;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.vo.ApprovalVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 审批服务实现类
 */
@Service
public class ApprovalServiceImpl implements ApprovalService {

    @Resource
    private DisabledAuditMapper disabledAuditMapper;

    @Resource
    private CompanyReductionMapper companyReductionMapper;

    @Resource
    private CompanyMapper companyMapper;

    @Resource
    private DisabledAuditService disabledAuditService;

    @Resource
    private ReductionService reductionService;

    @Override
    public Result<?> getPendingList(Integer page, Integer pageSize, String type, Long regionId) {
        if (page == null || page < 1) page = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;
        String queryType = type == null ? "all" : type;

        boolean districtScope = isDistrictAdmin();
        Long targetRegionId = districtScope ? getCurrentRegionId() : regionId;
        List<ApprovalVO> list = new ArrayList<>();

        if ("all".equals(queryType) || "disabled".equals(queryType)) {
            List<DisabledAudit> disabledList = disabledAuditMapper.selectByAuditStatus(0);
            for (int i = 0; i < disabledList.size(); i++) {
                DisabledAudit audit = disabledList.get(i);
                Company company = companyMapper.selectById(audit.getCompanyId());
                if (!canAccessCompany(company, districtScope, targetRegionId)) {
                    continue;
                }
                ApprovalVO vo = new ApprovalVO();
                vo.setId("D_" + audit.getId());
                vo.setCompanyName(company == null ? "未知单位" : company.getName());
                vo.setApplyType("残疾职工");
                vo.setApplyDate(audit.getAuditTime());
                vo.setStatus("待审批");
                vo.setEmployeeName(audit.getEmployeeName());
                vo.setIdCard(maskIdCard(audit.getIdCard()));
                vo.setDisabilityType(audit.getDisabilityType());
                vo.setDisabilityLevel(audit.getDisabilityLevel());
                vo.setHireDate(audit.getHireDate());
                vo.setAttachmentName(audit.getAttachment());
                vo.setDescription("新增残疾职工申请");
                list.add(vo);
            }
        }

        if ("all".equals(queryType) || "reduction".equals(queryType)) {
            List<CompanyReduction> reductionList = companyReductionMapper.selectByAuditStatus(0);
            for (int i = 0; i < reductionList.size(); i++) {
                CompanyReduction app = reductionList.get(i);
                Company company = companyMapper.selectById(app.getCompanyId());
                if (!canAccessCompany(company, districtScope, targetRegionId)) {
                    continue;
                }
                ApprovalVO vo = new ApprovalVO();
                vo.setId("R_" + app.getId());
                vo.setCompanyName(company == null ? "未知单位" : company.getName());
                vo.setApplyType("减免缓");
                vo.setApplyDate(app.getCreateTime());
                vo.setStatus("待审批");
                vo.setReductionType(getReductionTypeName(app.getApplyType()));
                vo.setApplyYear(String.valueOf(app.getYear()));
                vo.setApplyAmount(String.valueOf(app.getApplyAmount() == null ? 0 : app.getApplyAmount()));
                vo.setApplyReason(app.getReason());
                vo.setReductionAttachment(app.getAttachment());
                vo.setDescription(app.getReason());
                vo.setAmount("¥" + String.format("%,.2f", app.getApplyAmount() == null ? 0D : app.getApplyAmount()));
                list.add(vo);
            }
        }

        list = list.stream()
                .sorted((a, b) -> (b.getApplyDate() == null ? "" : b.getApplyDate()).compareTo(a.getApplyDate() == null ? "" : a.getApplyDate()))
                .collect(Collectors.toList());

        int total = list.size();
        int start = (page - 1) * pageSize;
        int end = Math.min(start + pageSize, total);
        List<ApprovalVO> pageList = start < total ? list.subList(start, end) : new ArrayList<>();
        
        Map<String, Object> result = new HashMap<>();
        result.put("list", pageList);
        result.put("total", total);
        return Result.success(result);
    }

    @Override
    public Result<?> approve(String approvalId) {
        if (approvalId == null || approvalId.trim().isEmpty()) {
            return Result.error("审批ID不能为空");
        }
        String id = approvalId.trim();
        if (id.startsWith("D_")) {
            return disabledAuditService.audit(parsePrefixedId(id), 1);
        }
        if (id.startsWith("R_")) {
            return reductionService.audit(parsePrefixedId(id), 1, "审批通过");
        }
        return Result.error("审批ID格式错误");
    }

    @Override
    public Result<?> reject(String approvalId, String reason) {
        if (approvalId == null || approvalId.trim().isEmpty()) {
            return Result.error("审批ID不能为空");
        }
        String rejectReason = (reason == null || reason.trim().isEmpty()) ? "审核不通过" : reason.trim();
        String id = approvalId.trim();
        if (id.startsWith("D_")) {
            return disabledAuditService.audit(parsePrefixedId(id), 2);
        }
        if (id.startsWith("R_")) {
            return reductionService.audit(parsePrefixedId(id), 2, rejectReason);
        }
        return Result.error("审批ID格式错误");
    }

    @Override
    public Result<?> getDetail(String approvalId) {
        if (approvalId == null || approvalId.trim().isEmpty()) {
            return Result.error("审批ID不能为空");
        }
        String id = approvalId.trim();
        if (id.startsWith("D_")) {
            DisabledAudit audit = disabledAuditMapper.selectById(parsePrefixedId(id));
            if (audit == null) {
                return Result.error("审批记录不存在");
            }
            Company company = companyMapper.selectById(audit.getCompanyId());
            ApprovalVO vo = new ApprovalVO();
            vo.setId("D_" + audit.getId());
            vo.setCompanyName(company == null ? "未知单位" : company.getName());
            vo.setApplyType("残疾职工");
            vo.setApplyDate(audit.getAuditTime());
            vo.setStatus(toStatusName(audit.getAuditStatus()));
            vo.setEmployeeName(audit.getEmployeeName());
            vo.setIdCard(maskIdCard(audit.getIdCard()));
            vo.setDisabilityType(audit.getDisabilityType());
            vo.setDisabilityLevel(audit.getDisabilityLevel());
            vo.setHireDate(audit.getHireDate());
            vo.setAttachmentName(audit.getAttachment());
            return Result.success(vo);
        }
        if (id.startsWith("R_")) {
            CompanyReduction reduction = companyReductionMapper.selectById(parsePrefixedId(id));
            if (reduction == null) {
                return Result.error("审批记录不存在");
            }
            Company company = companyMapper.selectById(reduction.getCompanyId());
            ApprovalVO vo = new ApprovalVO();
            vo.setId("R_" + reduction.getId());
            vo.setCompanyName(company == null ? "未知单位" : company.getName());
            vo.setApplyType("减免缓");
            vo.setApplyDate(reduction.getCreateTime());
            vo.setStatus(toStatusName(reduction.getAuditStatus()));
            vo.setReductionType(getReductionTypeName(reduction.getApplyType()));
            vo.setApplyYear(String.valueOf(reduction.getYear()));
            vo.setApplyAmount(String.valueOf(reduction.getApplyAmount() == null ? 0 : reduction.getApplyAmount()));
            vo.setApplyReason(reduction.getReason());
            vo.setReductionAttachment(reduction.getAttachment());
            return Result.success(vo);
        }
        return Result.error("审批ID格式错误");
    }

    @Override
    public Result<?> getStatistics() {
        Long currentRegionId = getCurrentRegionId();
        boolean districtScope = isDistrictAdmin();
        int pendingDisabled = 0;
        List<DisabledAudit> disabledList = disabledAuditMapper.selectByAuditStatus(0);
        for (int i = 0; i < disabledList.size(); i++) {
            Company company = companyMapper.selectById(disabledList.get(i).getCompanyId());
            if (canAccessCompany(company, districtScope, currentRegionId)) {
                pendingDisabled++;
            }
        }
        int pendingReduction = 0;
        List<CompanyReduction> reductions = companyReductionMapper.selectByAuditStatus(0);
        for (int i = 0; i < reductions.size(); i++) {
            Company company = companyMapper.selectById(reductions.get(i).getCompanyId());
            if (canAccessCompany(company, districtScope, currentRegionId)) {
                pendingReduction++;
            }
        }
        
        Map<String, Object> stats = new HashMap<>();
        stats.put("pendingTotal", pendingDisabled + pendingReduction);
        stats.put("pendingDisabled", pendingDisabled);
        stats.put("pendingReduction", pendingReduction);
        return Result.success(stats);
    }
    
    private String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 8) {
            return idCard;
        }
        return idCard.substring(0, 3) + "***********" + idCard.substring(idCard.length() - 4);
    }

    private Long parsePrefixedId(String id) {
        String[] parts = id.split("_");
        if (parts.length != 2) {
            throw new IllegalArgumentException("审批ID格式错误");
        }
        return Long.valueOf(parts[1]);
    }

    private String getReductionTypeName(Integer applyType) {
        if (applyType == null) return "减";
        switch (applyType) {
            case 1: return "减";
            case 2: return "免";
            case 3: return "缓";
            default: return "减";
        }
    }

    private String toStatusName(Integer status) {
        if (status == null || status == 0) return "待审批";
        if (status == 1) return "已通过";
        if (status == 2) return "已驳回";
        return "未知";
    }

    private boolean canAccessCompany(Company company, boolean districtScope, Long regionId) {
        if (company == null) {
            return false;
        }
        if (!districtScope && regionId == null) {
            return true;
        }
        if (regionId == null) {
            return false;
        }
        return regionId.equals(company.getRegionId());
    }

    private boolean isDistrictAdmin() {
        Map<String, Object> claims = getClaims();
        if (claims == null) {
            return false;
        }
        Object roleCodesObj = claims.get("roleCodes");
        if (!(roleCodesObj instanceof List)) {
            return false;
        }
        @SuppressWarnings("unchecked")
        List<String> roleCodes = (List<String>) roleCodesObj;
        return roleCodes.contains("admin_district");
    }

    private Long getCurrentRegionId() {
        Map<String, Object> claims = getClaims();
        if (claims == null) {
            return null;
        }
        Object regionIdObj = claims.get("regionId");
        if (regionIdObj == null) {
            return null;
        }
        return Long.valueOf(regionIdObj.toString());
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getClaims() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }
        HttpServletRequest request = attributes.getRequest();
        Object userInfo = request.getAttribute("userInfo");
        if (!(userInfo instanceof Map)) {
            return null;
        }
        return (Map<String, Object>) userInfo;
    }
}

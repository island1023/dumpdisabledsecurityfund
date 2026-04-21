package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.DisabledEmployee;
import com.example.dumpdisabledsecurityfund.entity.ReductionApplication;
import com.example.dumpdisabledsecurityfund.mapper.DisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.ReductionApplicationMapper;
import com.example.dumpdisabledsecurityfund.service.ApprovalService;
import com.example.dumpdisabledsecurityfund.vo.ApprovalVO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 审批服务实现类
 */
@Service
public class ApprovalServiceImpl implements ApprovalService {

    @Resource
    private DisabledEmployeeMapper disabledEmployeeMapper;

    @Resource
    private ReductionApplicationMapper reductionApplicationMapper;

    @Override
    public Result<?> getPendingList(Integer page, Integer pageSize, String type) {
        List<ApprovalVO> list = new ArrayList<>();
        
        // 获取待审核的残疾职工申请
        if ("all".equals(type) || "disabled".equals(type)) {
            List<DisabledEmployee> disabledList = disabledEmployeeMapper.selectByStatus(0);
            for (DisabledEmployee emp : disabledList) {
                ApprovalVO vo = new ApprovalVO();
                vo.setId(emp.getId());
                vo.setCompanyName(emp.getCompanyName() != null ? emp.getCompanyName() : "未知单位");
                vo.setApplyType("残疾职工");
                vo.setApplyDate(String.valueOf(emp.getYear()));
                vo.setStatus("待审批");
                vo.setEmployeeName(emp.getName());
                vo.setIdCard(maskIdCard(emp.getIdCard()));
                vo.setDisabilityType(emp.getDisabilityType());
                vo.setDisabilityLevel(emp.getDisabilityLevel());
                vo.setHireDate(emp.getHireDate());
                list.add(vo);
            }
        }
        
        // 获取待审核的减免缓申请
        if ("all".equals(type) || "reduction".equals(type)) {
            List<ReductionApplication> reductionList = reductionApplicationMapper.selectByStatus(0);
            for (ReductionApplication app : reductionList) {
                ApprovalVO vo = new ApprovalVO();
                vo.setId(app.getId());
                vo.setCompanyName(app.getCompanyName() != null ? app.getCompanyName() : "未知单位");
                vo.setApplyType("减免缓");
                vo.setApplyDate(String.valueOf(app.getApplyYear()));
                vo.setStatus("待审批");
                vo.setReductionType(app.getReductionType());
                vo.setApplyYear(String.valueOf(app.getApplyYear()));
                vo.setApplyAmount(String.valueOf(app.getApplyAmount()));
                vo.setApplyReason(app.getApplyReason());
                list.add(vo);
            }
        }
        
        // 分页处理
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
    public Result<?> approve(Long approvalId) {
        // 先尝试更新残疾职工
        DisabledEmployee disabledEmployee = disabledEmployeeMapper.selectById(approvalId);
        if (disabledEmployee != null) {
            disabledEmployee.setStatus(1);
            disabledEmployeeMapper.updateById(disabledEmployee);
            return Result.success("审批通过");
        }
        
        // 再尝试更新减免缓申请
        ReductionApplication reductionApp = reductionApplicationMapper.selectById(approvalId);
        if (reductionApp != null) {
            reductionApp.setStatus(1);
            reductionApplicationMapper.updateById(reductionApp);
            return Result.success("审批通过");
        }
        
        return Result.error("审批记录不存在");
    }

    @Override
    public Result<?> reject(Long approvalId, String reason) {
        // 先尝试更新残疾职工
        DisabledEmployee disabledEmployee = disabledEmployeeMapper.selectById(approvalId);
        if (disabledEmployee != null) {
            disabledEmployee.setStatus(2);
            disabledEmployeeMapper.updateById(disabledEmployee);
            return Result.success("审批已驳回");
        }
        
        // 再尝试更新减免缓申请
        ReductionApplication reductionApp = reductionApplicationMapper.selectById(approvalId);
        if (reductionApp != null) {
            reductionApp.setStatus(2);
            reductionApplicationMapper.updateById(reductionApp);
            return Result.success("审批已驳回");
        }
        
        return Result.error("审批记录不存在");
    }

    @Override
    public Result<?> getDetail(Long approvalId) {
        // 先尝试查询残疾职工
        DisabledEmployee disabledEmployee = disabledEmployeeMapper.selectById(approvalId);
        if (disabledEmployee != null) {
            ApprovalVO vo = new ApprovalVO();
            vo.setId(disabledEmployee.getId());
            vo.setCompanyName(disabledEmployee.getCompanyName());
            vo.setApplyType("残疾职工");
            vo.setApplyDate(String.valueOf(disabledEmployee.getYear()));
            vo.setStatus(disabledEmployee.getStatus() == 1 ? "已通过" : disabledEmployee.getStatus() == 2 ? "已驳回" : "待审批");
            vo.setEmployeeName(disabledEmployee.getName());
            vo.setIdCard(disabledEmployee.getIdCard());
            vo.setDisabilityType(disabledEmployee.getDisabilityType());
            vo.setDisabilityLevel(disabledEmployee.getDisabilityLevel());
            vo.setHireDate(disabledEmployee.getHireDate());
            return Result.success(vo);
        }
        
        // 再尝试查询减免缓申请
        ReductionApplication reductionApp = reductionApplicationMapper.selectById(approvalId);
        if (reductionApp != null) {
            ApprovalVO vo = new ApprovalVO();
            vo.setId(reductionApp.getId());
            vo.setCompanyName(reductionApp.getCompanyName());
            vo.setApplyType("减免缓");
            vo.setApplyDate(String.valueOf(reductionApp.getApplyYear()));
            vo.setStatus(reductionApp.getStatus() == 1 ? "已通过" : reductionApp.getStatus() == 2 ? "已驳回" : "待审批");
            vo.setReductionType(reductionApp.getReductionType());
            vo.setApplyYear(String.valueOf(reductionApp.getApplyYear()));
            vo.setApplyAmount(String.valueOf(reductionApp.getApplyAmount()));
            vo.setApplyReason(reductionApp.getApplyReason());
            return Result.success(vo);
        }
        
        return Result.error("审批记录不存在");
    }

    @Override
    public Result<?> getStatistics() {
        int pendingDisabled = disabledEmployeeMapper.selectByStatus(0).size();
        int pendingReduction = reductionApplicationMapper.selectByStatus(0).size();
        
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
}

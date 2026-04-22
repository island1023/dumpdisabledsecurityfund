package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.mapper.PaymentRecordMapper;
import com.example.dumpdisabledsecurityfund.service.CollectionService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.vo.CollectionStatisticsVO;
import com.example.dumpdisabledsecurityfund.vo.CollectionVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class CollectionServiceImpl implements CollectionService {

    @Resource
    private PayableAmountMapper payableAmountMapper;
    
    @Resource
    private CompanyMapper companyMapper;
    
    @Resource
    private PaymentRecordMapper paymentRecordMapper;
    @Resource
    private CompanyEmployeeMapper companyEmployeeMapper;

    @Override
    public Result<?> getStatistics(Integer year, Long regionId) {
        if (year == null) {
            year = DateUtil.getCurrentYear();
        }
        
        // 获取统计数据
        List<PayableAmount> allList = payableAmountMapper.selectByYear(year);
        List<PayableAmount> list = filterByRegionScope(allList, regionId);
        
        int totalUnits = list.size();
        int paidUnits = 0;
        int unpaidUnits = 0;
        double totalAmount = 0;
        double paidAmount = 0;
        double reductionAmount = 0;
        
        for (PayableAmount pa : list) {
            totalAmount += pa.getCalculatedAmount() != null ? pa.getCalculatedAmount() : 0;
            paidAmount += pa.getPaidAmount() != null ? pa.getPaidAmount() : 0;
            reductionAmount += pa.getReductionAmount() != null ? pa.getReductionAmount() : 0;
            
            if (pa.getPaymentStatus() != null) {
                if (pa.getPaymentStatus() == 2) {
                    paidUnits++;
                } else if (pa.getPaymentStatus() == 0) {
                    unpaidUnits++;
                }
            }
        }
        
        CollectionStatisticsVO statistics = new CollectionStatisticsVO();
        statistics.setTotalUnits(totalUnits);
        statistics.setPaidUnits(paidUnits);
        statistics.setUnpaidUnits(unpaidUnits);
        statistics.setTotalAmount(totalAmount);
        statistics.setPaidAmount(paidAmount);
        statistics.setReductionAmount(reductionAmount);
        
        return Result.success(statistics);
    }

    @Override
    public Result<?> getList(Integer year, String status, String keyword, Integer pageNum, Integer pageSize, Long regionId) {
        if (year == null) {
            year = DateUtil.getCurrentYear();
        }
        
        List<PayableAmount> rawList = payableAmountMapper.selectByYear(year);
        List<PayableAmount> scopedList = filterByRegionScope(rawList, regionId);
        List<PayableAmount> filteredList = new ArrayList<>();
        String kw = keyword == null ? "" : keyword.trim().toLowerCase();
        for (int i = 0; i < scopedList.size(); i++) {
            PayableAmount pa = scopedList.get(i);
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company == null) continue;
            if (status != null && !status.isEmpty()) {
                String current = "UNPAID";
                if (pa.getPaymentStatus() != null) {
                    if (pa.getPaymentStatus() == 1) current = "PARTIAL";
                    if (pa.getPaymentStatus() == 2) current = "PAID";
                }
                if (!status.equalsIgnoreCase(current)) {
                    continue;
                }
            }
            if (!kw.isEmpty()) {
                String name = company.getName() == null ? "" : company.getName().toLowerCase();
                if (!name.contains(kw)) {
                    continue;
                }
            }
            filteredList.add(pa);
        }
        int total = filteredList.size();
        int offset = (pageNum - 1) * pageSize;
        int end = Math.min(offset + pageSize, total);
        List<PayableAmount> payableList = offset < total ? filteredList.subList(offset, end) : new ArrayList<>();
        
        List<CollectionVO> resultList = new ArrayList<>();
        for (PayableAmount pa : payableList) {
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company == null) continue;
            
            CollectionVO vo = new CollectionVO();
            vo.setId(pa.getId());
            vo.setCompanyId(pa.getCompanyId());
            vo.setCompanyName(company.getName());
            vo.setCreditCode(company.getUnifiedSocialCreditCode());
            vo.setLegalPerson(company.getLegalPerson());
            vo.setRegisterAddress(company.getAddress());
            vo.setEstablishDate(company.getEstablishDate());
            vo.setPhone(company.getContactPhone());
            vo.setTotalEmployeeCount((int) companyEmployeeMapper.countEmployees(pa.getCompanyId()));
            vo.setEmployeeCount((int) companyEmployeeMapper.countActiveByCompanyId(pa.getCompanyId()));
            vo.setDisabledCount(pa.getDisabledEmployeeCount());
            vo.setYear(pa.getYear());
            vo.setStandardAmount(pa.getCalculatedAmount());
            vo.setReductionAmount(pa.getReductionAmount());
            vo.setPayableAmount(pa.getPayableAmount());
            vo.setPaidAmount(pa.getPaidAmount());
            
            // 转换状态
            String paymentStatus = "UNPAID";
            if (pa.getPaymentStatus() != null) {
                switch (pa.getPaymentStatus()) {
                    case 1: paymentStatus = "PARTIAL"; break;
                    case 2: paymentStatus = "PAID"; break;
                    default: paymentStatus = "UNPAID";
                }
            }
            vo.setStatus(paymentStatus);
            
            // 税务匹配状态（模拟）
            vo.setTaxDataMatch(pa.getPaymentStatus() != null && pa.getPaymentStatus() > 0);
            
            // 获取凭证号
            if (pa.getId() != null) {
                List<PaymentRecord> records = paymentRecordMapper.selectByPayableId(pa.getId());
                if (!records.isEmpty() && records.get(0).getVoucherNo() != null) {
                    vo.setVoucher(records.get(0).getVoucherNo());
                }
            }
            
            resultList.add(vo);
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("total", total);
        result.put("list", resultList);
        
        return Result.success(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> verifyPayment(Long collectionId, Double amount, String voucherNo, String remark) {
        if (collectionId == null || amount == null || amount <= 0) {
            return Result.error("核销参数不完整");
        }
        PayableAmount payable = payableAmountMapper.selectById(collectionId);
        if (payable == null) {
            return Result.error("征收记录不存在");
        }
        Double payableAmount = payable.getPayableAmount() == null ? 0D : payable.getPayableAmount();
        Double currentPaidAmount = payable.getPaidAmount() == null ? 0D : payable.getPaidAmount();
        Double remainingAmount = payableAmount - currentPaidAmount;
        if (remainingAmount <= 0) {
            return Result.error("该记录已完成核销");
        }
        double verifyAmount = Math.min(amount, remainingAmount);
        if (verifyAmount <= 0) {
            return Result.error("核销金额无效");
        }
        
        // 创建缴款记录
        PaymentRecord record = new PaymentRecord();
        record.setPayableId(collectionId);
        record.setActualAmount(verifyAmount);
        record.setPaymentDate(DateUtil.today());
        record.setVoucherNo(voucherNo);
        record.setRemark(remark);
        record.setSource(2); // 人工核销
        record.setStatus(1); // 已核销
        
        paymentRecordMapper.insert(record);

        double newPaidAmount = currentPaidAmount + verifyAmount;
        if (newPaidAmount > payableAmount) {
            newPaidAmount = payableAmount;
        }
        int paymentStatus = 0;
        if (newPaidAmount >= payableAmount && payableAmount > 0) {
            paymentStatus = 2;
        } else if (newPaidAmount > 0) {
            paymentStatus = 1;
        }
        PayableAmount update = new PayableAmount();
        update.setId(collectionId);
        update.setPaidAmount(newPaidAmount);
        update.setPaymentStatus(paymentStatus);
        payableAmountMapper.updateById(update);
        
        return Result.success("核销成功");
    }

    @Override
    public Result<?> getPaymentRecords(Long companyId) {
        // 获取单位所有年度的应缴记录
        List<PayableAmount> payableList = payableAmountMapper.selectByCompanyId(companyId);
        
        List<Map<String, Object>> resultList = new ArrayList<>();
        for (PayableAmount pa : payableList) {
            Map<String, Object> record = new HashMap<>();
            record.put("year", pa.getYear() + "年");
            record.put("payableAmount", pa.getPayableAmount());
            record.put("paidAmount", pa.getPaidAmount());
            
            String status = "未缴";
            if (pa.getPaymentStatus() != null) {
                switch (pa.getPaymentStatus()) {
                    case 1: status = "部分缴纳"; break;
                    case 2: status = "已缴"; break;
                    default: status = "未缴";
                }
            }
            record.put("status", status);
            
            // 获取缴款日期
            List<PaymentRecord> payments = paymentRecordMapper.selectByPayableId(pa.getId());
            if (!payments.isEmpty()) {
                record.put("payDate", payments.get(0).getPaymentDate());
            }
            
            resultList.add(record);
        }
        
        return Result.success(resultList);
    }

    private List<PayableAmount> filterByRegionScope(List<PayableAmount> source, Long regionIdFilter) {
        boolean districtScope = isDistrictAdmin();
        Long currentRegionId = getCurrentRegionId();
        Long targetRegionId = districtScope ? currentRegionId : regionIdFilter;
        if (targetRegionId == null) {
            return source;
        }
        List<PayableAmount> result = new ArrayList<>();
        for (int i = 0; i < source.size(); i++) {
            PayableAmount pa = source.get(i);
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company != null && targetRegionId.equals(company.getRegionId())) {
                result.add(pa);
            }
        }
        return result;
    }

    private boolean isDistrictAdmin() {
        Map<String, Object> claims = getClaims();
        if (claims == null) return false;
        Object roleCodesObj = claims.get("roleCodes");
        if (!(roleCodesObj instanceof List)) return false;
        @SuppressWarnings("unchecked")
        List<String> roleCodes = (List<String>) roleCodesObj;
        return roleCodes.contains("admin_district");
    }

    private Long getCurrentRegionId() {
        Map<String, Object> claims = getClaims();
        if (claims == null) return null;
        Object regionIdObj = claims.get("regionId");
        if (regionIdObj == null) return null;
        return Long.valueOf(String.valueOf(regionIdObj));
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getClaims() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) return null;
        HttpServletRequest request = attributes.getRequest();
        Object userInfo = request.getAttribute("userInfo");
        if (!(userInfo instanceof Map)) return null;
        return (Map<String, Object>) userInfo;
    }
}

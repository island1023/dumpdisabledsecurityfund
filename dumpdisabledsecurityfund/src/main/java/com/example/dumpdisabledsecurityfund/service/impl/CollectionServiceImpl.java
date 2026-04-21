package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.mapper.PaymentRecordMapper;
import com.example.dumpdisabledsecurityfund.service.CollectionService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.vo.CollectionStatisticsVO;
import com.example.dumpdisabledsecurityfund.vo.CollectionVO;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

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

    @Override
    public Result<?> getStatistics(Integer year) {
        if (year == null) {
            year = DateUtil.getCurrentYear();
        }
        
        // 获取统计数据
        List<PayableAmount> list = payableAmountMapper.selectByYear(year);
        
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
    public Result<?> getList(Integer year, String status, String keyword, Integer pageNum, Integer pageSize) {
        if (year == null) {
            year = DateUtil.getCurrentYear();
        }
        
        // 计算分页
        int offset = (pageNum - 1) * pageSize;
        
        // 查询数据
        List<PayableAmount> payableList = payableAmountMapper.selectByYearWithPage(year, status, keyword, offset, pageSize);
        int total = payableAmountMapper.countByYearWithFilter(year, status, keyword);
        
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
            vo.setEmployeeCount(company.getEmployeeCount());
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
        PayableAmount payable = payableAmountMapper.selectById(collectionId);
        if (payable == null) {
            return Result.error("征收记录不存在");
        }
        
        // 创建缴款记录
        PaymentRecord record = new PaymentRecord();
        record.setPayableId(collectionId);
        record.setActualAmount(amount);
        record.setPaymentDate(DateUtil.today());
        record.setVoucherNo(voucherNo);
        record.setRemark(remark);
        record.setSource(2); // 人工核销
        record.setStatus(1); // 已核销
        
        paymentRecordMapper.insert(record);
        
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
}

package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.mapper.PaymentRecordMapper;
import com.example.dumpdisabledsecurityfund.service.PaymentService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.vo.PaymentStatisticsVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class PaymentServiceImpl implements PaymentService {
    @Resource
    PayableAmountMapper payableAmountMapper;

    @Resource
    PaymentRecordMapper paymentRecordMapper;

    @Override
    public Result<?> getPaymentStatistics() {
        try {
            Long companyId = getCurrentCompanyId();
            if (companyId == null) {
                return Result.error("未登录或不是企业用户");
            }

            int currentYear = java.time.Year.now().getValue();
            List<PayableAmount> payableList = payableAmountMapper.selectByCompanyId(companyId);

            double totalAmount = mockTaxPlatformPayableAmount(companyId, currentYear);
            double paidAmount = 0;

            for (PayableAmount payable : payableList) {
                if (payable == null || payable.getYear() == null || payable.getId() == null) {
                    continue;
                }
                if (payable.getYear() == currentYear) {
                    List<PaymentRecord> records = paymentRecordMapper.selectByPayableId(payable.getId());
                    for (PaymentRecord record : records) {
                        if (record != null && record.getStatus() != null && record.getStatus() == 1) {
                            paidAmount += record.getActualAmount() == null ? 0 : record.getActualAmount();
                        }
                    }
                }
            }

            double pendingAmount = totalAmount - paidAmount;
            if (pendingAmount < 0) {
                pendingAmount = 0;
            }

            PaymentStatisticsVO vo = new PaymentStatisticsVO();
            vo.setPaidAmount(paidAmount);
            vo.setPendingAmount(pendingAmount);
            vo.setTotalAmount(totalAmount);
            vo.setYear(currentYear);

            return Result.success(vo);
        } catch (Exception e) {
            return Result.error("获取缴费统计失败：" + e.getMessage());
        }
    }

    /**
     * 模拟外部税务平台返回本年度应缴金额。
     * 这里按 companyId 做一个稳定的伪随机区间值，便于联调展示。
     */
    private double mockTaxPlatformPayableAmount(Long companyId, int year) {
        long seed = (companyId == null ? 1L : companyId) * 131 + year * 17L;
        double base = 180000D;
        double offset = (seed % 90000L);
        return base + offset;
    }

    @Override
    public Result<?> getPayments(Integer page, Integer pageSize) {
        try {
            if (page == null || page < 1) page = 1;
            if (pageSize == null || pageSize < 1) pageSize = 20;

            Long companyId = getCurrentCompanyId();
            if (companyId == null) {
                return Result.error("未登录或不是企业用户");
            }

            int offset = (page - 1) * pageSize;
            List<PaymentRecord> records = paymentRecordMapper.selectRecordsWithPage(companyId, offset, pageSize);
            long total = paymentRecordMapper.countRecords(companyId);

            List<Map<String, Object>> result = records.stream().map(record -> {
                Map<String, Object> map = new HashMap<>();
                if (record == null) {
                    map.put("id", "");
                    map.put("period", "");
                    map.put("amount", "￥0.00");
                    map.put("date", "");
                    map.put("status", "待缴费");
                    return map;
                }
                double amount = record.getActualAmount() == null ? 0 : record.getActualAmount();
                map.put("id", record.getId());
                map.put("period", record.getPaymentDate() == null ? "" : record.getPaymentDate());
                map.put("amount", "￥" + String.format("%.2f", amount));
                map.put("date", record.getPaymentDate() == null ? "" : record.getPaymentDate());
                map.put("status", record.getStatus() != null && record.getStatus() == 1 ? "已缴费" : "待缴费");
                return map;
            }).collect(Collectors.toList());

            Map<String, Object> data = new HashMap<>();
            data.put("total", total);
            data.put("list", result);

            return Result.success(data);
        } catch (Exception e) {
            return Result.error("获取缴费记录失败：" + e.getMessage());
        }
    }

    @Override
    public Result<?> getMockTaxPlatformSummary() {
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }
        int currentYear = java.time.Year.now().getValue();
        double payable = mockTaxPlatformPayableAmount(companyId, currentYear);
        Map<String, Object> data = new HashMap<>();
        data.put("source", "mock-tax-platform");
        data.put("companyId", companyId);
        data.put("year", currentYear);
        data.put("payableAmount", payable);
        return Result.success(data);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "导入税务数据", table = "payable_amount")
    public Result<?> importTaxData(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            for (List<String> row : list) {
                if (row.size() < 5) {
                    continue;
                }
                PayableAmount pa = new PayableAmount();
                pa.setCompanyId(Long.parseLong(row.get(0)));
                pa.setYear(Integer.parseInt(row.get(1)));
                pa.setTotalEmployeeCount(Integer.parseInt(row.get(2)));
                pa.setDisabledEmployeeCount(Integer.parseInt(row.get(3)));
                pa.setRequiredRatio(1.5D);
                pa.setCalculatedAmount(Double.parseDouble(row.get(4)));
                pa.setStatus(1);
                payableAmountMapper.insert(pa);
            }
            return Result.success("tax data import completed");
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
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
}

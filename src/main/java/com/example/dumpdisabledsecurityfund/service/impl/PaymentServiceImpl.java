package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.PaymentService;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

@Service
public class PaymentServiceImpl implements PaymentService {
    @Resource
    PayableAmountMapper payableAmountMapper;

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
}

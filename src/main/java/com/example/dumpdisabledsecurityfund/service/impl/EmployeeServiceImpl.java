package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.regex.Pattern;

@Service
public class EmployeeServiceImpl implements EmployeeService {
    @Resource
    private CompanyDisabledEmployeeMapper disabledEmployeeMapper;
    @Resource
    private CompanyEmployeeMapper employeeMapper;

    private static final Pattern ID_CARD_PATTERN = Pattern.compile("^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$");

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入残疾人职工", table = "company_disabled_employee")
    public Result<?> importDisabled(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            int errorCount = 0;

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                if (row.size() < 4) {
                    errorCount++;
                    continue;
                }

                String idCard = row.get(2).trim();
                if (!ID_CARD_PATTERN.matcher(idCard).matches()) {
                    errorCount++;
                    continue;
                }

                CompanyDisabledEmployee e = new CompanyDisabledEmployee();
                e.setCompanyId(Long.parseLong(row.get(0).trim()));
                e.setName(row.get(1).trim());
                e.setIdCard(idCard);
                e.setDisabilityCertNo(row.get(3).trim());
                e.setIsActive(1);
                e.setCreateTime(DateUtil.now());
                e.setUpdateTime(DateUtil.now());
                disabledEmployeeMapper.insert(e);
            }

            if (errorCount > 0) {
                return Result.success("导入完成，但有 " + errorCount + " 条数据格式错误被跳过");
            }
            return Result.success("disabled employees import completed");
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入普通职工", table = "company_employee")
    public Result<?> importNormal(MultipartFile file) {
        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            int errorCount = 0;

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                if (row.size() < 3) {
                    errorCount++;
                    continue;
                }

                String idCard = row.get(2).trim();
                if (!ID_CARD_PATTERN.matcher(idCard).matches()) {
                    errorCount++;
                    continue;
                }

                CompanyEmployee e = new CompanyEmployee();
                e.setCompanyId(Long.parseLong(row.get(0).trim()));
                e.setName(row.get(1).trim());
                e.setIdCard(idCard);
                e.setIsActive(1);
                e.setCreateTime(DateUtil.now());
                e.setUpdateTime(DateUtil.now());
                employeeMapper.insert(e);
            }

            if (errorCount > 0) {
                return Result.success("导入完成，但有 " + errorCount + " 条数据格式错误被跳过");
            }
            return Result.success("employees import completed");
        } catch (Exception ex) {
            throw new RuntimeException("导入失败: " + ex.getMessage(), ex);
        }
    }
}

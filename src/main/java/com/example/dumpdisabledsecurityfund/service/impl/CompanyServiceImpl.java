package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyUserMapper;
import com.example.dumpdisabledsecurityfund.service.CompanyService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

@Service
public class CompanyServiceImpl implements CompanyService {
    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private CompanyUserMapper companyUserMapper;

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    private static final Pattern CREDIT_CODE_PATTERN = Pattern.compile("^[0-9A-HJ-NPQRTUWXY]{2}\\d{6}[0-9A-HJ-NPQRTUWXY]{10}$");

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入公司", table = "company")
    public Result<?> importExcel(MultipartFile file) {
        List<String> errors = new ArrayList<>();
        int successCount = 0;

        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                if (row.size() < 5) {
                    errors.add("第" + (i + 2) + "行数据不完整");
                    continue;
                }

                try {
                    String creditCode = row.get(0).trim();
                    String name = row.get(1).trim();
                    String regionIdStr = row.get(2).trim();
                    String legalPerson = row.get(3).trim();
                    String contactPhone = row.get(4).trim();

                    if (creditCode.isEmpty()) {
                        errors.add("第" + (i + 2) + "行：统一社会信用代码不能为空");
                        continue;
                    }

                    if (!CREDIT_CODE_PATTERN.matcher(creditCode).matches()) {
                        errors.add("第" + (i + 2) + "行：统一社会信用代码格式错误");
                        continue;
                    }

                    if (name.isEmpty()) {
                        errors.add("第" + (i + 2) + "行：单位名称不能为空");
                        continue;
                    }

                    if (regionIdStr.isEmpty()) {
                        errors.add("第" + (i + 2) + "行：地区ID不能为空");
                        continue;
                    }

                    Long regionId;
                    try {
                        regionId = Long.parseLong(regionIdStr);
                    } catch (NumberFormatException e) {
                        errors.add("第" + (i + 2) + "行：地区ID格式错误");
                        continue;
                    }

                    if (!contactPhone.isEmpty() && !PHONE_PATTERN.matcher(contactPhone).matches()) {
                        errors.add("第" + (i + 2) + "行：手机号格式错误");
                        continue;
                    }

                    Company company = new Company();
                    company.setUnifiedSocialCreditCode(creditCode);
                    company.setName(name);
                    company.setRegionId(regionId);
                    company.setLegalPerson(legalPerson);
                    company.setContactPhone(contactPhone);
                    company.setStatus(1);
                    company.setCreateTime(DateUtil.now());
                    company.setUpdateTime(DateUtil.now());
                    companyMapper.insert(company);

                    String suffix = creditCode.length() > 6 ? creditCode.substring(creditCode.length() - 6) : creditCode;
                    String username = "COMP" + suffix;
                    String pwd = PasswordUtil.randomPwd(8);
                    CompanyUser user = new CompanyUser();
                    user.setCompanyId(company.getId());
                    user.setUsername(username);
                    user.setPassword(PasswordUtil.encrypt(pwd));
                    user.setName(name + "管理员");
                    user.setStatus(1);
                    user.setCreateTime(DateUtil.now());
                    user.setUpdateTime(DateUtil.now());
                    companyUserMapper.insert(user);

                    successCount++;
                } catch (Exception e) {
                    errors.add("第" + (i + 2) + "行导入失败: " + e.getMessage());
                }
            }

            Map<String, Object> result = new HashMap<>();
            result.put("successCount", successCount);
            result.put("errorCount", errors.size());
            result.put("errors", errors);

            if (successCount == 0) {
                return Result.error("导入失败，没有成功导入任何数据");
            }

            return Result.success("导入完成，成功" + successCount + "条，失败" + errors.size() + "条", result);
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }
}

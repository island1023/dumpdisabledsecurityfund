package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import com.example.dumpdisabledsecurityfund.entity.Region;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.service.CompanyService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import com.example.dumpdisabledsecurityfund.vo.CompanyDetailVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class CompanyServiceImpl implements CompanyService {
    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private CompanyUserMapper companyUserMapper;
    @Resource
    private CompanyEmployeeMapper companyEmployeeMapper;
    @Resource
    private CompanyDisabledEmployeeMapper companyDisabledEmployeeMapper;
    @Resource
    private RegionMapper regionMapper;

    private static final Pattern PHONE_PATTERN = Pattern.compile("^1[3-9]\\d{9}$");
    private static final Pattern CREDIT_CODE_PATTERN = Pattern.compile("^[0-9A-HJ-NPQRTUWXY]{2}\\d{6}[0-9A-HJ-NPQRTUWXY]{10}$");

    @Override
    public Result<?> list(String keyword, Integer pageNum, Integer pageSize) {
        if (pageNum == null || pageNum < 1) pageNum = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        int offset = (pageNum - 1) * pageSize;
        List<Company> companies = companyMapper.selectCompaniesWithPage(keyword, offset, pageSize);
        long total = companyMapper.countCompanies(keyword);

        List<CompanyDetailVO> voList = companies.stream().map(this::convertToDetailVO).collect(Collectors.toList());
        PageResult<CompanyDetailVO> pageResult = PageResult.build(total, pageNum, pageSize, voList);

        return Result.success(pageResult);
    }

    @Override
    public Result<?> getDetail(Long id) {
        try {
            Company company = companyMapper.selectById(id);
            if (company == null) {
                return Result.error("企业不存在");
            }

            CompanyDetailVO vo = convertToDetailVO(company);

            Long companyId = company.getId();
            long totalEmployees = companyEmployeeMapper.countEmployees(companyId);
            long disabledEmployees = companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);

            vo.setTotalEmployees((int) totalEmployees);
            vo.setDisabledEmployees((int) disabledEmployees);

            return Result.success(vo);
        } catch (Exception e) {
            return Result.error("获取单位详情失败：" + e.getMessage());
        }
    }

    @Override
    public Result<?> getCurrentCompanyInfo() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes == null) {
                return Result.error("无法获取请求上下文");
            }

            HttpServletRequest request = attributes.getRequest();
            Object companyIdObj = request.getAttribute("companyId");

            if (companyIdObj == null) {
                return Result.error("未登录或不是企业用户");
            }


            Long companyId = Long.valueOf(companyIdObj.toString());
            Map<String, Object> info = companyMapper.selectInfoMapById(companyId);
            if (info == null || info.isEmpty()) {
                return Result.error("企业不存在");
            }

            long totalEmployees = companyEmployeeMapper.countActiveByCompanyId(companyId);
            long disabledEmployees = companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);
            info.put("totalEmployees", totalEmployees);
            info.put("disabledEmployees", disabledEmployees);



            Integer status = null;
            Object statusObj = info.get("status");
            if (statusObj instanceof Number) {
                status = ((Number) statusObj).intValue();
            } else if (statusObj != null) {
                try {
                    status = Integer.parseInt(statusObj.toString());
                } catch (NumberFormatException ignored) {
                    status = null;
                }
            }
            info.put("statusName", status != null && status == 1 ? "正常" : "异常");

            return Result.success(info);
        } catch (Exception e) {
            return Result.error("获取当前单位信息失败：" + e.getMessage());
        }
    }

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

            return Result.success("导入完成", result);
        } catch (Exception e) {
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    private CompanyDetailVO convertToDetailVO(Company company) {
        CompanyDetailVO vo = new CompanyDetailVO();
        BeanUtils.copyProperties(company, vo);

        if (company.getStatus() != null) {
            vo.setStatusName(company.getStatus() == 1 ? "正常" : "注销");
        }

        if (company.getRegionId() != null) {
            Region region = regionMapper.selectById(company.getRegionId());
            if (region != null) {
                vo.setRegionName(region.getName());
            }
        }

        return vo;
    }
}


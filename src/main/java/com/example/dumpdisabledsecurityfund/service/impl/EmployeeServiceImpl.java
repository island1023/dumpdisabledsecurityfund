package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.vo.DisabledEmployeeDetailVO;
import com.example.dumpdisabledsecurityfund.vo.EmployeeListVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;
import org.springframework.web.multipart.MultipartFile;

import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class EmployeeServiceImpl implements EmployeeService {
    @Resource
    private CompanyDisabledEmployeeMapper disabledEmployeeMapper;
    @Resource
    private CompanyEmployeeMapper employeeMapper;

    private static final Pattern ID_CARD_PATTERN = Pattern.compile("^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$");

    @Override
    public Result<?> getAllEmployees(Integer page, Integer pageSize) {
        if (page == null || page < 1) page = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        int offset = (page - 1) * pageSize;
        List<CompanyEmployee> employees = employeeMapper.selectEmployeesWithPage(companyId, offset, pageSize);
        long total = employeeMapper.countEmployees(companyId);

        List<EmployeeListVO> voList = employees.stream().map(this::convertToEmployeeVO).collect(Collectors.toList());
        PageResult<EmployeeListVO> pageResult = PageResult.build(total, page, pageSize, voList);

        return Result.success(pageResult);
    }

    @Override
    public Result<?> getDisabledEmployees() {
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<CompanyDisabledEmployee> employees = disabledEmployeeMapper.selectByCompanyIdAndStatus(companyId, 1);

        List<Map<String, Object>> result = employees.stream().map(emp -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", emp.getId());
            map.put("name", emp.getName());
            map.put("idCard", maskIdCard(emp.getIdCard()));
            map.put("disabilityLevel", emp.getDisabilityLevel());
            map.put("certificate", "有效");
            return map;
        }).collect(Collectors.toList());

        return Result.success(result);
    }

    @Override
    public Result<?> getDisabledEmployeeDetail(Long employeeId) {
        CompanyDisabledEmployee employee = disabledEmployeeMapper.selectById(employeeId);
        if (employee == null) {
            return Result.error("员工不存在");
        }

        DisabledEmployeeDetailVO vo = new DisabledEmployeeDetailVO();
        BeanUtils.copyProperties(employee, vo);

        if (employee.getIsActive() != null) {
            vo.setIsActiveName(employee.getIsActive() == 1 ? "在职" : "离职");
        }

        return Result.success(vo);
    }

    @Override
    public Result<?> getNonDisabledEmployees() {
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<CompanyEmployee> employees = employeeMapper.selectByCompanyId(companyId);

        List<Map<String, Object>> result = employees.stream().map(emp -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", emp.getId());
            map.put("name", emp.getName());
            map.put("idCard", maskIdCard(emp.getIdCard()));
            return map;
        }).collect(Collectors.toList());

        return Result.success(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "新增普通职工", table = "company_employee")
    public Result<?> addEmployee(Object request) {
        if (!(request instanceof Map)) {
            return Result.error("请求参数格式错误");
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> reqMap = (Map<String, Object>) request;
        String mode = (String) reqMap.get("mode");

        if ("manual".equals(mode)) {
            @SuppressWarnings("unchecked")
            Map<String, Object> employeeData = (Map<String, Object>) reqMap.get("employee");

            CompanyEmployee employee = new CompanyEmployee();
            employee.setCompanyId(getCurrentCompanyId());
            employee.setName((String) employeeData.get("name"));
            employee.setIdCard((String) employeeData.get("idCard"));
            employee.setJobPosition((String) employeeData.get("jobPosition"));
            employee.setEntryDate((String) employeeData.get("hireDate"));
            employee.setIsActive(1);
            employee.setCreateTime(DateUtil.now());
            employee.setUpdateTime(DateUtil.now());

            employeeMapper.insert(employee);

            Map<String, Object> result = new HashMap<>();
            result.put("id", employee.getId());
            return Result.success("添加成功", result);
        } else {
            return Result.success("批量导入请使用导入接口");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "新增残疾职工", table = "company_disabled_employee")
    public Result<?> addDisabledEmployees(Object request) {
        if (!(request instanceof Map)) {
            return Result.error("请求参数格式错误");
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> reqMap = (Map<String, Object>) request;

        @SuppressWarnings("unchecked")
        List<Object> employeeIds = (List<Object>) reqMap.get("employeeIds");

        if (employeeIds == null || employeeIds.isEmpty()) {
            return Result.error("请选择要设置的员工");
        }

        String disabilityType = (String) reqMap.get("disabilityType");
        String disabilityLevel = (String) reqMap.get("disabilityLevel");

        int successCount = 0;
        for (Object empIdObj : employeeIds) {
            Long empId = Long.valueOf(empIdObj.toString());

            CompanyEmployee normalEmp = employeeMapper.selectById(empId);
            if (normalEmp != null) {
                CompanyDisabledEmployee disabledEmp = new CompanyDisabledEmployee();
                disabledEmp.setCompanyId(normalEmp.getCompanyId());
                disabledEmp.setName(normalEmp.getName());
                disabledEmp.setIdCard(normalEmp.getIdCard());
                disabledEmp.setDisabilityType(disabilityType);
                disabledEmp.setDisabilityLevel(disabilityLevel);
                disabledEmp.setJobPosition(normalEmp.getJobPosition());
                disabledEmp.setEntryDate(normalEmp.getEntryDate());
                disabledEmp.setIsActive(1);
                disabledEmp.setCreateTime(DateUtil.now());
                disabledEmp.setUpdateTime(DateUtil.now());

                disabledEmployeeMapper.insert(disabledEmp);
                successCount++;
            }
        }

        return Result.success("成功设置" + successCount + "名残疾职工");
    }

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

    private String maskIdCard(String idCard) {
        if (idCard == null || idCard.length() < 12) {
            return idCard;
        }
        return idCard.substring(0, 3) + "***********" + idCard.substring(idCard.length() - 4);
    }

    private EmployeeListVO convertToEmployeeVO(CompanyEmployee emp) {
        EmployeeListVO vo = new EmployeeListVO();
        BeanUtils.copyProperties(emp, vo);

        if (emp.getIsActive() != null) {
            vo.setIsActiveName(emp.getIsActive() == 1 ? "在职" : "离职");
        }

        vo.setIdCard(maskIdCard(emp.getIdCard()));

        return vo;
    }
}


package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.CompanyDisabledEmployee;
import com.example.dumpdisabledsecurityfund.entity.CompanyEmployee;
import com.example.dumpdisabledsecurityfund.entity.DisabledAudit;
import com.example.dumpdisabledsecurityfund.entity.DisabledEmployeeAttachment;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.DisabledAuditMapper;
import com.example.dumpdisabledsecurityfund.mapper.DisabledEmployeeAttachmentMapper;
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

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.*;
import java.util.regex.Pattern;
import java.util.stream.Collectors;

@Service
public class EmployeeServiceImpl implements EmployeeService {
    @Resource
    private CompanyDisabledEmployeeMapper companyDisabledEmployeeMapper;
    @Resource
    private CompanyEmployeeMapper employeeMapper;
    @Resource
    private DisabledAuditMapper disabledAuditMapper;
    @Resource
    private DisabledEmployeeAttachmentMapper attachmentMapper;

    private static final Pattern ID_CARD_PATTERN = Pattern.compile("^[1-9]\\d{5}(18|19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])\\d{3}[\\dXx]$");
    private static final String UPLOAD_DIR = "uploads/disability_attachments/";



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

        List<CompanyDisabledEmployee> employees = companyDisabledEmployeeMapper.selectByCompanyIdAndStatus(companyId, 1);

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
        CompanyDisabledEmployee employee = companyDisabledEmployeeMapper.selectById(employeeId);
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
        List<CompanyDisabledEmployee> disabledEmployees = companyDisabledEmployeeMapper.selectByCompanyIdAndStatus(companyId, 1);
        Set<String> disabledIdCards = disabledEmployees.stream()
                .map(CompanyDisabledEmployee::getIdCard)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        List<CompanyEmployee> nonDisabledEmployees = employees.stream()
                .filter(emp -> emp.getIdCard() == null || !disabledIdCards.contains(emp.getIdCard()))
                .collect(Collectors.toList());

        List<Map<String, Object>> result = nonDisabledEmployees.stream().map(emp -> {
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
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<CompanyDisabledEmployee> disabledEmployees = companyDisabledEmployeeMapper.selectByCompanyIdAndStatus(companyId, 1);
        Set<String> disabledIdCards = disabledEmployees.stream()
                .map(CompanyDisabledEmployee::getIdCard)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        int successCount = 0;
        for (Object empIdObj : employeeIds) {
            Long empId = Long.valueOf(empIdObj.toString());

            CompanyEmployee normalEmp = employeeMapper.selectById(empId);
            if (normalEmp != null && companyId.equals(normalEmp.getCompanyId())) {
                if (normalEmp.getIdCard() != null && disabledIdCards.contains(normalEmp.getIdCard())) {
                    continue;
                }
                CompanyDisabledEmployee disabledEmp = new CompanyDisabledEmployee();
                disabledEmp.setCompanyId(normalEmp.getCompanyId());
                disabledEmp.setName(normalEmp.getName());
                disabledEmp.setIdCard(normalEmp.getIdCard());
                disabledEmp.setDisabilityCertNo(buildDisabilityCertNo(normalEmp));
                disabledEmp.setDisabilityType(disabilityType);
                disabledEmp.setDisabilityLevel(disabilityLevel);
                disabledEmp.setJobPosition(normalEmp.getJobPosition());
                disabledEmp.setEntryDate(normalEmp.getEntryDate());
                disabledEmp.setIsActive(1);
                disabledEmp.setAuditPassTime(DateUtil.now());
                disabledEmp.setCreateTime(DateUtil.now());
                disabledEmp.setUpdateTime(DateUtil.now());

                companyDisabledEmployeeMapper.insert(disabledEmp);
                if (normalEmp.getIdCard() != null) {
                    disabledIdCards.add(normalEmp.getIdCard());
                }
                successCount++;
            }
        }

        return Result.success("成功设置" + successCount + "名残疾职工");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> submitDisabledAuditApplications(Object request) {
        if (!(request instanceof Map)) {
            return Result.error("请求参数格式错误");
        }
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> reqMap = (Map<String, Object>) request;
        @SuppressWarnings("unchecked")
        List<Object> employeeIds = (List<Object>) reqMap.get("employeeIds");
        if (employeeIds == null || employeeIds.isEmpty()) {
            return Result.error("请选择要申请的职工");
        }

        List<CompanyDisabledEmployee> disabledEmployees = companyDisabledEmployeeMapper.selectByCompanyIdAndStatus(companyId, 1);
        Set<String> disabledIdCards = disabledEmployees.stream()
                .map(CompanyDisabledEmployee::getIdCard)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        List<DisabledAudit> audits = disabledAuditMapper.selectByCompanyId(companyId);
        Set<String> pendingIdCards = audits.stream()
                .filter(a -> a.getAuditStatus() != null && a.getAuditStatus() == 0)
                .map(DisabledAudit::getIdCard)
                .filter(Objects::nonNull)
                .collect(Collectors.toSet());

        int successCount = 0;
        String now = DateUtil.now();
        int year = Integer.parseInt(now.substring(0, 4));
        for (Object empIdObj : employeeIds) {
            Long empId = Long.valueOf(empIdObj.toString());
            CompanyEmployee employee = employeeMapper.selectById(empId);
            if (employee == null || !companyId.equals(employee.getCompanyId())) {
                continue;
            }
            if (employee.getIdCard() != null && (disabledIdCards.contains(employee.getIdCard()) || pendingIdCards.contains(employee.getIdCard()))) {
                continue;
            }

            DisabledAudit audit = new DisabledAudit();
            audit.setCompanyId(companyId);
            audit.setYear(year);
            audit.setEmployeeName(employee.getName());
            audit.setIdCard(employee.getIdCard());
            audit.setAuditStatus(0);
            audit.setAuditTime(now);
            disabledAuditMapper.insert(audit);
            if (employee.getIdCard() != null) {
                pendingIdCards.add(employee.getIdCard());
            }
            successCount++;
        }
        Map<String, Object> result = new HashMap<>();
        result.put("successCount", successCount);
        return Result.success("成功提交" + successCount + "条残疾职工审核申请", result);
    }
    @Override
    public Result<?> getDisabledAuditApplications() {
        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        List<DisabledAudit> audits = disabledAuditMapper.selectByCompanyId(companyId);

        List<Map<String, Object>> result = audits.stream().map(audit -> {
            Map<String, Object> map = new HashMap<>();
            map.put("id", audit.getId());
            map.put("employeeName", audit.getEmployeeName());
            map.put("idCard", maskIdCard(audit.getIdCard()));
            map.put("year", audit.getYear());
            map.put("auditStatus", audit.getAuditStatus());
            map.put("auditStatusName", getAuditStatusName(audit.getAuditStatus()));
            map.put("auditTime", audit.getAuditTime());
            return map;
        }).collect(Collectors.toList());

        return Result.success(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入残疾职工", table = "company_disabled_employee")
    public Result<?> importDisabled(MultipartFile file) {
        System.out.println("\n>>> 开始批量导入残疾职工");
        System.out.println(">>> 文件名: " + (file != null ? file.getOriginalFilename() : "null"));
        System.out.println(">>> 文件大小: " + (file != null ? file.getSize() : 0) + " bytes");

        if (file == null || file.isEmpty()) {
            return Result.error("文件不能为空");
        }

        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            System.out.println(">>> Excel读取成功，共 " + list.size() + " 行数据");

            int successCount = 0;
            int failCount = 0;
            List<Map<String, Object>> errors = new ArrayList<>();

            Long companyId = getCurrentCompanyId();
            if (companyId == null) {
                return Result.error("未登录或不是企业用户");
            }

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                System.out.println(">>> 处理第 " + (i + 2) + " 行数据");

                if (row.size() < 6) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("message", "列数不足，至少需要6列: 姓名、身份证号、岗位、入职日期、残疾证号、残疾等级");
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行跳过: 列数不足\n");
                    continue;
                }

                try {
                    String name = row.get(0).trim();
                    String idCard = row.get(1).trim();
                    String jobPosition = row.size() > 2 ? row.get(2).trim() : "";
                    String entryDate = row.size() > 3 ? row.get(3).trim() : "";
                    String disabilityCertNo = row.get(4).trim();
                    String disabilityLevel = row.size() > 5 ? row.get(5).trim() : "";

                    System.out.println("   - 姓名: " + name);
                    System.out.println("   - 身份证号: " + idCard);
                    System.out.println("   - 残疾证号: " + disabilityCertNo);

                    if (name.isEmpty()) {
                        throw new RuntimeException("姓名不能为空");
                    }

                    if (!ID_CARD_PATTERN.matcher(idCard).matches()) {
                        throw new RuntimeException("身份证号格式不正确");
                    }

                    if (disabilityCertNo.isEmpty()) {
                        throw new RuntimeException("残疾证号不能为空");
                    }

                    CompanyDisabledEmployee existingDisabled =
                            companyDisabledEmployeeMapper.selectByCompanyIdAndIdCard(companyId, idCard);
                    if (existingDisabled != null) {
                        throw new RuntimeException("该残疾职工已存在");
                    }

                    CompanyDisabledEmployee disabledEmp = new CompanyDisabledEmployee();
                    disabledEmp.setCompanyId(companyId);
                    disabledEmp.setName(name);
                    disabledEmp.setIdCard(idCard);
                    disabledEmp.setDisabilityCertNo(disabilityCertNo);
                    disabledEmp.setDisabilityLevel(disabilityLevel);
                    disabledEmp.setJobPosition(jobPosition);
                    disabledEmp.setEntryDate(entryDate);
                    disabledEmp.setIsActive(1);
                    disabledEmp.setCreateTime(DateUtil.now());
                    disabledEmp.setUpdateTime(DateUtil.now());

                    companyDisabledEmployeeMapper.insert(disabledEmp);
                    successCount++;
                    System.out.println("   ✓ 残疾职工导入成功\n");

                } catch (Exception e) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("name", row.get(0));
                    error.put("message", e.getMessage());
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行导入失败: " + e.getMessage() + "\n");
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("successCount", successCount);
            data.put("failCount", failCount);
            data.put("errors", errors);

            System.out.println("\n========================================");
            System.out.println(">>> 导入完成统计:");
            System.out.println(">>> 总行数: " + list.size());
            System.out.println(">>> 成功: " + successCount + " 条");
            System.out.println(">>> 失败: " + failCount + " 条");
            System.out.println("========================================\n");

            String message = String.format("成功导入 %d 条残疾职工，失败 %d 条", successCount, failCount);
            return Result.success(message, data);

        } catch (Exception e) {
            System.err.println("\n>>> 批量导入残疾职工发生异常: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入普通职工", table = "company_employee")
    public Result<?> importNormal(MultipartFile file) {
        System.out.println("\n>>> 开始批量导入普通职工");
        System.out.println(">>> 文件名: " + (file != null ? file.getOriginalFilename() : "null"));
        System.out.println(">>> 文件大小: " + (file != null ? file.getSize() : 0) + " bytes");

        if (file == null || file.isEmpty()) {
            return Result.error("文件不能为空");
        }

        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            System.out.println(">>> Excel读取成功，共 " + list.size() + " 行数据");

            int successCount = 0;
            int failCount = 0;
            List<Map<String, Object>> errors = new ArrayList<>();

            Long companyId = getCurrentCompanyId();
            if (companyId == null) {
                return Result.error("未登录或不是企业用户");
            }

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                System.out.println(">>> 处理第 " + (i + 2) + " 行数据");

                if (row.size() < 3) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("message", "列数不足，至少需要3列: 姓名、身份证号、岗位");
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行跳过: 列数不足\n");
                    continue;
                }

                try {
                    String name = row.get(0).trim();
                    String idCard = row.get(1).trim();
                    String jobPosition = row.size() > 2 ? row.get(2).trim() : "";
                    String entryDate = row.size() > 3 ? row.get(3).trim() : "";

                    System.out.println("   - 姓名: " + name);
                    System.out.println("   - 身份证号: " + idCard);

                    if (name.isEmpty()) {
                        throw new RuntimeException("姓名不能为空");
                    }

                    if (!ID_CARD_PATTERN.matcher(idCard).matches()) {
                        throw new RuntimeException("身份证号格式不正确");
                    }

                    CompanyEmployee existingNormal =
                            employeeMapper.selectByCompanyIdAndIdCard(companyId, idCard);
                    if (existingNormal != null) {
                        throw new RuntimeException("该职工已存在");
                    }

                    CompanyEmployee normalEmp = new CompanyEmployee();
                    normalEmp.setCompanyId(companyId);
                    normalEmp.setName(name);
                    normalEmp.setIdCard(idCard);
                    normalEmp.setJobPosition(jobPosition);
                    normalEmp.setEntryDate(entryDate);
                    normalEmp.setIsActive(1);
                    normalEmp.setCreateTime(DateUtil.now());
                    normalEmp.setUpdateTime(DateUtil.now());

                    employeeMapper.insert(normalEmp);
                    successCount++;
                    System.out.println("   ✓ 普通职工导入成功\n");

                } catch (Exception e) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("name", row.get(0));
                    error.put("message", e.getMessage());
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行导入失败: " + e.getMessage() + "\n");
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("successCount", successCount);
            data.put("failCount", failCount);
            data.put("errors", errors);

            System.out.println("\n========================================");
            System.out.println(">>> 导入完成统计:");
            System.out.println(">>> 总行数: " + list.size());
            System.out.println(">>> 成功: " + successCount + " 条");
            System.out.println(">>> 失败: " + failCount + " 条");
            System.out.println("========================================\n");

            String message = String.format("成功导入 %d 条普通职工，失败 %d 条", successCount, failCount);
            return Result.success(message, data);

        } catch (Exception e) {
            System.err.println("\n>>> 批量导入普通职工发生异常: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入单位全体职工", table = "company_employee,company_disabled_employee")
    public Result<?> importAllEmployees(MultipartFile file) {
        System.out.println("\n>>> 开始批量导入单位全体职工");
        System.out.println(">>> 文件名: " + (file != null ? file.getOriginalFilename() : "null"));
        System.out.println(">>> 文件大小: " + (file != null ? file.getSize() : 0) + " bytes");

        if (file == null || file.isEmpty()) {
            return Result.error("文件不能为空");
        }

        try {
            List<List<String>> list = ExcelUtil.readExcel(file);
            System.out.println(">>> Excel读取成功，共 " + list.size() + " 行数据");

            int successCount = 0;
            int disabledCount = 0;
            int normalCount = 0;
            int updateCount = 0;
            int failCount = 0;
            List<Map<String, Object>> errors = new ArrayList<>();

            Long companyId = getCurrentCompanyId();
            if (companyId == null) {
                return Result.error("未登录或不是企业用户");
            }

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                System.out.println(">>> 处理第 " + (i + 2) + " 行数据");

                if (row.size() < 5) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("message", "列数不足，至少需要5列: 姓名、身份证号、是否残疾");
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行跳过: 列数不足\n");
                    continue;
                }

                try {
                    String name = row.get(0).trim();
                    String idCard = row.get(1).trim();
                    String jobPosition = row.size() > 2 ? row.get(2).trim() : "";
                    String entryDate = row.size() > 3 ? row.get(3).trim() : "";
                    String isDisabled = row.get(4).trim();

                    System.out.println("   - 姓名: " + name);
                    System.out.println("   - 身份证号: " + idCard);
                    System.out.println("   - 是否残疾: " + isDisabled);

                    if (name.isEmpty()) {
                        throw new RuntimeException("姓名不能为空");
                    }

                    if (!ID_CARD_PATTERN.matcher(idCard).matches()) {
                        throw new RuntimeException("身份证号格式不正确");
                    }

                    if (isDisabled.equals("是") || isDisabled.equals("yes") || isDisabled.equals("1")) {
                        if (row.size() < 6) {
                            throw new RuntimeException("残疾职工必须填写残疾证号");
                        }

                        String disabilityCertNo = row.get(5).trim();
                        String disabilityLevel = row.size() > 6 ? row.get(6).trim() : "";

                        if (disabilityCertNo.isEmpty()) {
                            throw new RuntimeException("残疾证号不能为空");
                        }

                        CompanyDisabledEmployee existingDisabled =
                                companyDisabledEmployeeMapper.selectByCompanyIdAndIdCard(companyId, idCard);

                        if (existingDisabled != null) {
                            existingDisabled.setName(name);
                            existingDisabled.setDisabilityCertNo(disabilityCertNo);
                            existingDisabled.setDisabilityLevel(disabilityLevel);
                            existingDisabled.setJobPosition(jobPosition);
                            existingDisabled.setEntryDate(entryDate);
                            existingDisabled.setIsActive(1);
                            existingDisabled.setUpdateTime(DateUtil.now());

                            companyDisabledEmployeeMapper.updateById(existingDisabled);
                            updateCount++;
                            disabledCount++;
                            System.out.println("   ✓ 残疾职工信息更新成功（已存在）\n");
                        } else {
                            CompanyDisabledEmployee disabledEmp = new CompanyDisabledEmployee();
                            disabledEmp.setCompanyId(companyId);
                            disabledEmp.setName(name);
                            disabledEmp.setIdCard(idCard);
                            disabledEmp.setDisabilityCertNo(disabilityCertNo);
                            disabledEmp.setDisabilityLevel(disabilityLevel);
                            disabledEmp.setJobPosition(jobPosition);
                            disabledEmp.setEntryDate(entryDate);
                            disabledEmp.setIsActive(1);
                            disabledEmp.setCreateTime(DateUtil.now());
                            disabledEmp.setUpdateTime(DateUtil.now());

                            companyDisabledEmployeeMapper.insert(disabledEmp);
                            disabledCount++;
                            System.out.println("   ✓ 残疾职工导入成功（新增）\n");
                        }
                    } else {
                        CompanyEmployee existingNormal =
                                employeeMapper.selectByCompanyIdAndIdCard(companyId, idCard);

                        if (existingNormal != null) {
                            existingNormal.setName(name);
                            existingNormal.setJobPosition(jobPosition);
                            existingNormal.setEntryDate(entryDate);
                            existingNormal.setIsActive(1);
                            existingNormal.setUpdateTime(DateUtil.now());

                            employeeMapper.updateById(existingNormal);
                            updateCount++;
                            normalCount++;
                            System.out.println("   ✓ 普通职工信息更新成功（已存在）\n");
                        } else {
                            CompanyEmployee normalEmp = new CompanyEmployee();
                            normalEmp.setCompanyId(companyId);
                            normalEmp.setName(name);
                            normalEmp.setIdCard(idCard);
                            normalEmp.setJobPosition(jobPosition);
                            normalEmp.setEntryDate(entryDate);
                            normalEmp.setIsActive(1);
                            normalEmp.setCreateTime(DateUtil.now());
                            normalEmp.setUpdateTime(DateUtil.now());

                            employeeMapper.insert(normalEmp);
                            normalCount++;
                            System.out.println("   ✓ 普通职工导入成功（新增）\n");
                        }
                    }

                    successCount++;

                } catch (Exception e) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("name", row.get(0));
                    error.put("message", e.getMessage());
                    errors.add(error);
                    System.err.println("<<< 第 " + (i + 2) + " 行导入失败: " + e.getMessage() + "\n");
                }
            }

            Map<String, Object> data = new HashMap<>();
            data.put("successCount", successCount);
            data.put("disabledCount", disabledCount);
            data.put("normalCount", normalCount);
            data.put("updateCount", updateCount);
            data.put("failCount", failCount);
            data.put("errors", errors);

            System.out.println("\n========================================");
            System.out.println(">>> 导入完成统计:");
            System.out.println(">>> 总行数: " + list.size());
            System.out.println(">>> 成功: " + successCount + " 条");
            System.out.println(">>>   - 残疾职工: " + disabledCount + " 条");
            System.out.println(">>>   - 普通职工: " + normalCount + " 条");
            System.out.println(">>>   - 其中更新: " + updateCount + " 条");
            System.out.println(">>> 失败: " + failCount + " 条");
            System.out.println("========================================\n");

            String message = String.format("成功导入 %d 条（残疾职工 %d 条，普通职工 %d 条，更新 %d 条），失败 %d 条",
                    successCount, disabledCount, normalCount, updateCount, failCount);
            return Result.success(message, data);

        } catch (Exception e) {
            System.err.println("\n>>> 批量导入全体职工发生异常: " + e.getMessage());
            e.printStackTrace();
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }


    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "上传残疾人证", table = "disabled_employee_attachment")
    public Result<?> uploadDisabilityCertificate(MultipartFile file, Long employeeId) {
        System.out.println("\n>>> 开始上传残疾人证");
        System.out.println(">>> 职工ID: " + employeeId);
        System.out.println(">>> 文件名: " + (file != null ? file.getOriginalFilename() : "null"));
        System.out.println(">>> 文件大小: " + (file != null ? file.getSize() : 0) + " bytes");
        System.out.println(">>> Content-Type: " + (file != null ? file.getContentType() : "null"));

        if (file == null || file.isEmpty()) {
            return Result.error("文件不能为空");
        }

        if (employeeId == null) {
            return Result.error("职工ID不能为空");
        }

        CompanyDisabledEmployee employee = companyDisabledEmployeeMapper.selectById(employeeId);
        if (employee == null) {
            return Result.error("职工不存在，ID: " + employeeId);
        }

        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || originalFilename.isEmpty()) {
            return Result.error("文件名无效");
        }

        if (!isImageFile(originalFilename, file.getContentType())) {
            return Result.error("只支持上传图片文件（JPG、PNG、GIF格式）");
        }

        long maxSize = 10 * 1024 * 1024;
        if (file.getSize() > maxSize) {
            return Result.error("图片大小不能超过10MB");
        }

        try {
            List<DisabledEmployeeAttachment> existingAttachments = attachmentMapper.selectByEmployeeId(employeeId);
            if (!existingAttachments.isEmpty()) {
                for (DisabledEmployeeAttachment existing : existingAttachments) {
                    attachmentMapper.deleteById(existing.getId());
                    try {
                        Path oldFilePath = Paths.get(existing.getFileUrl().replaceFirst("^/", ""));
                        if (Files.exists(oldFilePath)) {
                            Files.delete(oldFilePath);
                            System.out.println(">>> 删除旧残疾人证: " + oldFilePath.toAbsolutePath());
                        }
                    } catch (Exception e) {
                        System.err.println(">>> 删除旧文件失败: " + e.getMessage());
                    }
                }
                System.out.println(">>> 已删除旧的残疾人证");
            }

            String extension = getFileExtension(originalFilename);
            String fileName = UUID.randomUUID().toString() + extension;

            Path uploadPath = Paths.get(UPLOAD_DIR + "disability_cert");
            if (!Files.exists(uploadPath)) {
                Files.createDirectories(uploadPath);
                System.out.println(">>> 创建上传目录: " + uploadPath.toAbsolutePath());
            }

            Path filePath = uploadPath.resolve(fileName);
            Files.copy(file.getInputStream(), filePath);
            System.out.println(">>> 残疾人证保存成功: " + filePath.toAbsolutePath());
            System.out.println(">>> 文件大小: " + formatFileSize(file.getSize()));

            String fileUrl = "/uploads/disability_attachments/disability_cert/" + fileName;

            DisabledEmployeeAttachment attachment = new DisabledEmployeeAttachment();
            attachment.setEmployeeId(employeeId);
            attachment.setFileName(originalFilename);
            attachment.setFileUrl(fileUrl);
            attachment.setFileSize(file.getSize());
            attachment.setFileType(file.getContentType());
            attachment.setUploadTime(DateUtil.now());
            attachment.setCreateTime(DateUtil.now());

            attachmentMapper.insert(attachment);
            System.out.println(">>> 残疾人证记录插入成功，ID: " + attachment.getId());

            Map<String, Object> result = new HashMap<>();
            result.put("id", attachment.getId());
            result.put("url", fileUrl);
            result.put("fileName", originalFilename);
            result.put("fileSize", formatFileSize(file.getSize()));

            System.out.println(">>> 残疾人证上传完成\n");
            return Result.success("上传成功", result);

        } catch (IOException e) {
            System.err.println(">>> 残疾人证上传失败: " + e.getMessage());
            e.printStackTrace();
            return Result.error("上传失败：" + e.getMessage());
        }
    }

    @Override
    public Result<?> getDisabilityCertificate(Long employeeId) {
        System.out.println("\n>>> 查询残疾人证，职工ID: " + employeeId);

        if (employeeId == null) {
            return Result.error("职工ID不能为空");
        }

        CompanyDisabledEmployee employee = companyDisabledEmployeeMapper.selectById(employeeId);
        if (employee == null) {
            return Result.error("职工不存在，ID: " + employeeId);
        }

        List<DisabledEmployeeAttachment> attachments = attachmentMapper.selectByEmployeeId(employeeId);

        if (attachments.isEmpty()) {
            System.out.println(">>> 未找到残疾人证\n");
            return Result.success(null);
        }

        DisabledEmployeeAttachment cert = attachments.get(0);
        Map<String, Object> result = new HashMap<>();
        result.put("id", cert.getId());
        result.put("fileName", cert.getFileName());
        result.put("fileUrl", cert.getFileUrl());
        result.put("fileSize", formatFileSize(cert.getFileSize()));
        result.put("uploadTime", cert.getUploadTime());

        System.out.println(">>> 残疾人证查询完成\n");
        return Result.success(result);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "删除残疾人证", table = "disabled_employee_attachment")
    public Result<?> deleteDisabilityCertificate(Long attachmentId) {
        System.out.println("\n>>> 删除残疾人证，附件ID: " + attachmentId);

        if (attachmentId == null) {
            return Result.error("附件ID不能为空");
        }

        DisabledEmployeeAttachment attachment = attachmentMapper.selectById(attachmentId);
        if (attachment == null) {
            return Result.error("附件不存在，ID: " + attachmentId);
        }

        try {
            Path filePath = Paths.get(attachment.getFileUrl().replaceFirst("^/", ""));
            if (Files.exists(filePath)) {
                Files.delete(filePath);
                System.out.println(">>> 物理文件删除成功: " + filePath.toAbsolutePath());
            }

            int result = attachmentMapper.deleteById(attachmentId);
            if (result > 0) {
                System.out.println(">>> 残疾人证删除成功\n");
                return Result.success("删除成功");
            } else {
                return Result.error("删除失败");
            }
        } catch (IOException e) {
            System.err.println(">>> 删除物理文件失败: " + e.getMessage());
            return Result.error("删除文件失败：" + e.getMessage());
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

    private String buildDisabilityCertNo(CompanyEmployee employee) {
        String now = DateUtil.now();
        String compact = now.replace("-", "").replace(":", "").replace(" ", "");
        String suffix = employee.getId() == null ? "0000" : String.valueOf(employee.getId());
        return "AUTO" + compact + suffix;
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

    private String getAuditStatusName(Integer status) {
        if (status == null) {
            return "审批中";
        }
        switch (status) {
            case 0: return "审批中";
            case 1: return "已通过";
            case 2: return "已驳回";
            default: return "未知";
        }
    }

    private boolean isImageFile(String fileName, String contentType) {
        if (fileName == null) {
            return false;
        }

        String lowerName = fileName.toLowerCase();
        boolean validExtension = lowerName.endsWith(".jpg") ||
                lowerName.endsWith(".jpeg") ||
                lowerName.endsWith(".png") ||
                lowerName.endsWith(".gif");

        boolean validContentType = contentType != null &&
                (contentType.startsWith("image/") ||
                        contentType.equals("application/octet-stream"));

        return validExtension && validContentType;
    }

    private String getFileExtension(String fileName) {
        if (fileName == null || !fileName.contains(".")) {
            return ".jpg";
        }
        return fileName.substring(fileName.lastIndexOf("."));
    }

    private String formatFileSize(Long size) {
        if (size == null || size == 0) {
            return "0 B";
        }
        final String[] units = {"B", "KB", "MB", "GB"};
        int unitIndex = 0;
        double fileSize = size.doubleValue();
        while (fileSize >= 1024 && unitIndex < units.length - 1) {
            fileSize /= 1024;
            unitIndex++;
        }
        return String.format("%.2f %s", fileSize, units[unitIndex]);
    }
}
package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.LogOperation;
import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.SysUserCreateDTO;
import com.example.dumpdisabledsecurityfund.dto.SysUserUpdateDTO;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import com.example.dumpdisabledsecurityfund.entity.Region;
import com.example.dumpdisabledsecurityfund.entity.SysUser;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.mapper.SysUserMapper;
import com.example.dumpdisabledsecurityfund.service.SysUserService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.ExcelUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import com.example.dumpdisabledsecurityfund.vo.ResetPasswordVO;
import com.example.dumpdisabledsecurityfund.vo.SysUserVO;
import jakarta.annotation.Resource;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class SysUserServiceImpl implements SysUserService {
    @Resource
    private SysUserMapper sysUserMapper;

    @Resource
    private RegionMapper regionMapper;

    @Resource
    private CompanyMapper companyMapper;

    @Resource
    private CompanyUserMapper companyUserMapper;

    @Override
    public Result<?> list(String keyword, Integer pageNum, Integer pageSize) {
        if (pageNum == null || pageNum < 1) pageNum = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        int offset = (pageNum - 1) * pageSize;
        List<SysUser> users = sysUserMapper.selectUsersWithPage(keyword, offset, pageSize);
        List<CompanyUser> companyUsers = companyUserMapper.selectAll();
        List<CompanyUser> filteredCompanyUsers = companyUsers.stream()
                .filter(item -> matchCompanyUserKeyword(item, keyword))
                .collect(Collectors.toList());

        long total = sysUserMapper.countUsers(keyword) + filteredCompanyUsers.size();

        List<SysUserVO> voList = users.stream().map(this::convertToVO).collect(Collectors.toList());
        for (CompanyUser companyUser : filteredCompanyUsers) {
            voList.add(convertCompanyUserToVO(companyUser));
        }
        PageResult<SysUserVO> pageResult = PageResult.build(total, pageNum, pageSize, voList);

        return Result.success(pageResult);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "创建系统用户", table = "sys_user")
    public Result<?> create(SysUserCreateDTO dto) {
        SysUser existingUser = sysUserMapper.selectByUsername(dto.getUsername());
        if (existingUser != null) {
            return Result.error("用户名已存在");
        }
        CompanyUser existingCompanyUser = companyUserMapper.selectByUsername(dto.getUsername());
        if (existingCompanyUser != null) {
            return Result.error("用户名已存在");
        }

        String role = dto.getRole() == null ? "" : dto.getRole().trim().toUpperCase();
        if ("UNIT".equals(role)) {
            return createCompanyUser(dto);
        }

        SysUser user = new SysUser();
        user.setUsername(dto.getUsername());
        user.setRealName(dto.getRealName());
        user.setPassword(PasswordUtil.encrypt("123456"));
        user.setStatus(1);
        
        // 转换角色编码为userType和adminLevel
        convertRoleToUserType(dto.getRole(), user);
        
        // 处理地区
        if (dto.getDistrict() != null && !dto.getDistrict().isEmpty()) {
            Region region = regionMapper.selectByName(dto.getDistrict());
            if (region != null) {
                user.setRegionId(region.getId());
            }
        }
        
        user.setCreateTime(DateUtil.now());
        user.setUpdateTime(DateUtil.now());

        sysUserMapper.insert(user);

        Map<String, Object> data = new HashMap<>();
        data.put("id", String.valueOf(user.getId()));
        data.put("username", user.getUsername());
        data.put("password", "123456");

        return Result.success("创建成功", data);
    }

    private Result<?> createCompanyUser(SysUserCreateDTO dto) {
        if (dto.getCompanyId() == null) {
            return Result.error("创建单位用户时 companyId 不能为空");
        }
        Company company = companyMapper.selectById(dto.getCompanyId());
        if (company == null) {
            return Result.error("所选单位不存在");
        }

        CompanyUser companyUser = new CompanyUser();
        companyUser.setCompanyId(dto.getCompanyId());
        companyUser.setUsername(dto.getUsername());
        companyUser.setPassword(PasswordUtil.encrypt("123456"));
        companyUser.setName(dto.getRealName());
        companyUser.setStatus(1);
        companyUser.setCreateTime(DateUtil.now());
        companyUser.setUpdateTime(DateUtil.now());
        companyUserMapper.insert(companyUser);

        Map<String, Object> data = new HashMap<>();
        data.put("id", String.valueOf(companyUser.getId()));
        data.put("username", companyUser.getUsername());
        data.put("password", "123456");
        data.put("accountType", "company");
        return Result.success("创建成功", data);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "更新系统用户", table = "sys_user")
    public Result<?> update(SysUserUpdateDTO dto) {
        SysUser user = sysUserMapper.selectById(dto.getId());
        if (user == null) {
            return Result.error("用户不存在");
        }

        user.setUsername(dto.getUsername());
        user.setRealName(dto.getRealName());
        convertRoleToUserType(dto.getRole(), user);
        
        if (dto.getDistrict() != null && !dto.getDistrict().isEmpty()) {
            Region region = regionMapper.selectByName(dto.getDistrict());
            if (region != null) {
                user.setRegionId(region.getId());
            }
        } else {
            user.setRegionId(null);
        }
        
        user.setUpdateTime(DateUtil.now());

        sysUserMapper.updateById(user);
        return Result.success("更新成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "删除系统用户", table = "sys_user")
    public Result<?> delete(Long id) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        sysUserMapper.deleteById(id);
        return Result.success("删除成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "切换用户状态", table = "sys_user")
    public Result<?> toggleStatus(Long id, Integer status) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        user.setStatus(status);
        user.setUpdateTime(DateUtil.now());
        sysUserMapper.updateById(user);

        return Result.success("操作成功");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "重置用户密码", table = "sys_user")
    public Result<?> resetPassword(Long id) {
        SysUser user = sysUserMapper.selectById(id);
        if (user == null) {
            return Result.error("用户不存在");
        }

        String newPassword = "123456";
        String encryptedPassword = PasswordUtil.encrypt(newPassword);
        sysUserMapper.updatePassword(id, encryptedPassword, DateUtil.now());

        ResetPasswordVO vo = new ResetPasswordVO();
        vo.setNewPassword(newPassword);

        return Result.success("密码重置成功", vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    @LogOperation(value = "批量导入系统用户", table = "sys_user")
    public Result<?> importExcel(MultipartFile file) {
        System.out.println("\n>>> SysUserServiceImpl.importExcel 开始执行");
        System.out.println(">>> 原始文件名: " + file.getOriginalFilename());
        System.out.println(">>> 文件大小: " + file.getSize() + " bytes");
        System.out.println(">>> Content-Type: " + file.getContentType());

        try {
            System.out.println(">>> 步骤1: 开始读取Excel文件内容...");
            List<List<String>> list = ExcelUtil.readExcel(file);
            System.out.println(">>> 步骤1完成: Excel读取成功，共 " + list.size() + " 行数据\n");

            int successCount = 0;
            int failCount = 0;
            List<Map<String, Object>> errors = new ArrayList<>();

            for (int i = 0; i < list.size(); i++) {
                List<String> row = list.get(i);
                System.out.println(">>> 步骤2: 处理第 " + (i + 2) + " 行数据 (Excel第" + (i+2) + "行)");

                if (row.size() < 3) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("username", row.size() > 0 ? row.get(0) : "");
                    error.put("message", "列数不足，至少需要3列: username, realName, role");
                    errors.add(error);
                    System.out.println("<<< 第 " + (i + 2) + " 行跳过: 列数不足 (" + row.size() + "列)\n");
                    continue;
                }

                try {
                    String username = row.get(0);
                    String realName = row.get(1);
                    String roleCode = row.get(2);
                    String districtName = row.size() > 3 ? row.get(3) : "";
                    String companyIdStr = row.size() > 4 ? row.get(4) : "";

                    System.out.println("   - 用户名: " + username);
                    System.out.println("   - 姓名: " + realName);
                    System.out.println("   - 角色: " + roleCode);
                    System.out.println("   - 地区: " + districtName);
                    System.out.println("   - 单位ID: " + companyIdStr);

                    if (username == null || username.trim().isEmpty()) {
                        throw new RuntimeException("用户名不能为空");
                    }
                    if (realName == null || realName.trim().isEmpty()) {
                        throw new RuntimeException("姓名不能为空");
                    }
                    if (roleCode == null || roleCode.trim().isEmpty()) {
                        throw new RuntimeException("角色编码不能为空");
                    }

                    String role = roleCode.trim().toUpperCase();

                    SysUser existingUser = sysUserMapper.selectByUsername(username.trim());
                    if (existingUser != null) {
                        throw new RuntimeException("用户名已存在");
                    }

                    CompanyUser existingCompanyUser = companyUserMapper.selectByUsername(username.trim());
                    if (existingCompanyUser != null) {
                        throw new RuntimeException("用户名已存在");
                    }

                    if ("UNIT".equals(role)) {
                        System.out.println("    创建单位负责人账号");

                        if (companyIdStr == null || companyIdStr.trim().isEmpty()) {
                            throw new RuntimeException("单位负责人必须填写单位ID");
                        }

                        Long companyId;
                        try {
                            companyId = Long.parseLong(companyIdStr.trim());
                        } catch (NumberFormatException e) {
                            throw new RuntimeException("单位ID格式错误: " + companyIdStr);
                        }

                        Company company = companyMapper.selectById(companyId);
                        if (company == null) {
                            throw new RuntimeException("单位不存在，ID: " + companyId);
                        }

                        CompanyUser companyUser = new CompanyUser();
                        companyUser.setCompanyId(companyId);
                        companyUser.setUsername(username.trim());
                        companyUser.setPassword(PasswordUtil.encrypt("123456"));
                        companyUser.setName(realName.trim());
                        companyUser.setStatus(1);
                        companyUser.setCreateTime(DateUtil.now());
                        companyUser.setUpdateTime(DateUtil.now());
                        companyUserMapper.insert(companyUser);

                        System.out.println("    单位负责人账号创建成功\n");
                    } else {
                        System.out.println("    创建系统用户账号，角色: " + role);

                        SysUser user = new SysUser();
                        user.setUsername(username.trim());
                        user.setPassword(PasswordUtil.encrypt("123456"));
                        user.setRealName(realName.trim());
                        convertRoleToUserType(role, user);

                        if ("CITY_ADMIN".equals(role) || "CITY_LEADER".equals(role)) {
                            districtName = "成都市";
                            System.out.println("    市级角色，自动设置地区为成都市");
                        }

                        if (districtName != null && !districtName.trim().isEmpty()) {
                            Region region = regionMapper.selectByName(districtName.trim());
                            if (region == null) {
                                throw new RuntimeException("地区不存在: " + districtName);
                            }
                            user.setRegionId(region.getId());
                            System.out.println("    设置地区ID: " + region.getId() + " (" + region.getName() + ")");
                        }

                        user.setStatus(1);
                        user.setCreateTime(DateUtil.now());
                        user.setUpdateTime(DateUtil.now());

                        sysUserMapper.insert(user);
                        System.out.println("    系统用户账号创建成功，ID: " + user.getId() + "\n");
                    }

                    successCount++;
                    System.out.println("<<< 第 " + (i + 2) + " 行导入成功\n");
                } catch (Exception e) {
                    failCount++;
                    Map<String, Object> error = new HashMap<>();
                    error.put("row", i + 2);
                    error.put("username", row.get(0));
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

            String message = String.format("成功导入 %d 条，失败 %d 条", successCount, failCount);
            return Result.success(message, data);
        } catch (Exception e) {
            System.err.println("\n\n SysUserServiceImpl.importExcel 发生严重异常 ");
            System.err.println("异常类型: " + e.getClass().getName());
            System.err.println("异常消息: " + e.getMessage());
            System.err.println("完整堆栈:");
            e.printStackTrace();
            System.err.println("\n");
            throw new RuntimeException("导入失败: " + e.getMessage(), e);
        }
    }



    private SysUserVO convertToVO(SysUser user) {
        SysUserVO vo = new SysUserVO();
        vo.setId(String.valueOf(user.getId()));
        vo.setUsername(user.getUsername());
        vo.setRealName(user.getRealName());
        vo.setRole(convertToRoleCode(user));
        vo.setRoleName(convertToRoleName(user));
        
        if (user.getRegionId() != null) {
            Region region = regionMapper.selectById(user.getRegionId());
            if (region != null) {
                vo.setDistrictCode(region.getCode());
                vo.setDistrictName(region.getName());
            }
        } else {
            vo.setDistrictCode("");
            vo.setDistrictName("");
        }
        
        vo.setStatus(user.getStatus() == 1 ? "启用" : "禁用");
        vo.setCreateTime(user.getCreateTime() != null ? user.getCreateTime().substring(0, 10) : "");
        vo.setUpdateTime(user.getUpdateTime() != null ? user.getUpdateTime().substring(0, 10) : "");

        return vo;
    }

    private SysUserVO convertCompanyUserToVO(CompanyUser user) {
        SysUserVO vo = new SysUserVO();
        vo.setId(String.valueOf(user.getId()));
        vo.setUsername(user.getUsername());
        vo.setRealName(user.getName());
        vo.setRole("UNIT");
        vo.setRoleName("单位负责人");

        Company company = companyMapper.selectById(user.getCompanyId());
        if (company != null && company.getRegionId() != null) {
            Region region = regionMapper.selectById(company.getRegionId());
            if (region != null) {
                vo.setDistrictCode(region.getCode());
                vo.setDistrictName(region.getName());
            } else {
                vo.setDistrictCode("");
                vo.setDistrictName("");
            }
        } else {
            vo.setDistrictCode("");
            vo.setDistrictName("");
        }

        vo.setStatus(user.getStatus() != null && user.getStatus() == 1 ? "启用" : "禁用");
        vo.setCreateTime(user.getCreateTime() != null && user.getCreateTime().length() >= 10 ? user.getCreateTime().substring(0, 10) : "");
        vo.setUpdateTime(user.getUpdateTime() != null && user.getUpdateTime().length() >= 10 ? user.getUpdateTime().substring(0, 10) : "");
        return vo;
    }

    private boolean matchCompanyUserKeyword(CompanyUser user, String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return true;
        }
        String kw = keyword.trim().toLowerCase();
        String username = user.getUsername() == null ? "" : user.getUsername().toLowerCase();
        String realName = user.getName() == null ? "" : user.getName().toLowerCase();
        return username.contains(kw) || realName.contains(kw);
    }

    private String convertToRoleCode(SysUser user) {
        if (user.getUserType() != null && user.getUserType() == 3) {
            return "UNIT";
        }

        if (user.getUserType() != null && user.getUserType() == 2) {
            if (user.getAdminLevel() != null) {
                switch (user.getAdminLevel()) {
                    case 2: return "CITY_LEADER";
                    case 3: return "DISTRICT_LEADER";
                    default: return "DISTRICT_LEADER";
                }
            }
            return "DISTRICT_LEADER";
        }
        
        if (user.getAdminLevel() != null) {
            switch (user.getAdminLevel()) {
                case 1: return "SYSTEM_ADMIN";
                case 2: return "CITY_ADMIN";
                case 3: return "DISTRICT_ADMIN";
                default: return "SYSTEM_ADMIN";
            }
        }
        return "SYSTEM_ADMIN";
    }

    private String convertToRoleName(SysUser user) {
        String roleCode = convertToRoleCode(user);
        switch (roleCode) {
            case "SYSTEM_ADMIN": return "系统管理员";
            case "CITY_ADMIN": return "市级管理员";
            case "DISTRICT_ADMIN": return "区级管理员";
            case "CITY_LEADER": return "市级领导";
            case "DISTRICT_LEADER": return "区级领导";
            case "UNIT": return "单位负责人";
            default: return "未知角色";
        }
    }

    private void convertRoleToUserType(String role, SysUser user) {
        switch (role) {
            case "SYSTEM_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(1);
                break;
            case "CITY_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(2);
                break;
            case "DISTRICT_ADMIN":
                user.setUserType(1);
                user.setAdminLevel(3);
                break;
            case "CITY_LEADER":
                user.setUserType(2);
                user.setAdminLevel(2);
                break;
            case "DISTRICT_LEADER":
                user.setUserType(2);
                user.setAdminLevel(3);
                break;
            case "UNIT":
                user.setUserType(3);
                user.setAdminLevel(null);
                break;
            default:
                user.setUserType(1);
                user.setAdminLevel(1);
        }
    }
}

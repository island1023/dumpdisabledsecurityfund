package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.CaptchaStore;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ChangePasswordDTO;
import com.example.dumpdisabledsecurityfund.dto.LoginDTO;
import com.example.dumpdisabledsecurityfund.entity.CompanyUser;
import com.example.dumpdisabledsecurityfund.entity.SysUser;
import com.example.dumpdisabledsecurityfund.mapper.CompanyUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.SysUserMapper;
import com.example.dumpdisabledsecurityfund.mapper.UserRoleMapper;
import com.example.dumpdisabledsecurityfund.service.AuthService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
import com.example.dumpdisabledsecurityfund.util.JwtUtil;
import com.example.dumpdisabledsecurityfund.util.PasswordUtil;
import jakarta.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class AuthServiceImpl implements AuthService {
    @Resource
    private CompanyUserMapper companyUserMapper;
    @Resource
    private SysUserMapper sysUserMapper;
    @Resource
    private UserRoleMapper userRoleMapper;
    @Resource
    private CaptchaStore captchaStore;

    @Override
    public Result<?> captcha() {
        return Result.success(captchaStore.create());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> login(LoginDTO dto) {
        if (dto == null || dto.getUsername() == null || dto.getPassword() == null) {
            return Result.error("username and password are required");
        }
        if (!captchaStore.validate(dto.getCaptchaKey(), dto.getCaptchaCode())) {
            return Result.error("captcha invalid or expired");
        }

        String accountType = dto.getAccountType();
        if (accountType != null) {
            accountType = accountType.trim().toLowerCase();
        }

        // 显式指定账户类型时，按类型精确登录，避免 sys/company 同名账号串角色
        if ("company".equals(accountType)) {
            CompanyUser companyUser = companyUserMapper.selectByUsername(dto.getUsername());
            if (companyUser == null) {
                return Result.error("单位账号不存在");
            }
            return loginCompanyUser(companyUser, dto.getPassword());
        }
        if ("sys".equals(accountType)) {
            SysUser sysUser = sysUserMapper.selectByUsername(dto.getUsername());
            if (sysUser == null) {
                return Result.error("系统账号不存在");
            }
            return loginSystemUser(sysUser, dto.getPassword());
        }

        SysUser sysUser = sysUserMapper.selectByUsername(dto.getUsername());
        if (sysUser != null) {
            return loginSystemUser(sysUser, dto.getPassword());
        }

        CompanyUser companyUser = companyUserMapper.selectByUsername(dto.getUsername());
        if (companyUser != null) {
            return loginCompanyUser(companyUser, dto.getPassword());
        }
        return Result.error("account not found");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> changePassword(Long userId, String accountType, ChangePasswordDTO dto) {
        if (userId == null || accountType == null) {
            return Result.error("用户信息缺失");
        }

        if (!dto.getNewPassword().equals(dto.getConfirmPassword())) {
            return Result.error("两次输入的新密码不一致");
        }

        if (dto.getNewPassword().length() < 6) {
            return Result.error("新密码长度不能少于6位");
        }

        try {
            if ("sys".equals(accountType)) {
                return changeSysUserPassword(userId, dto);
            } else if ("company".equals(accountType)) {
                return changeCompanyUserPassword(userId, dto);
            } else {
                return Result.error("无效的账户类型");
            }
        } catch (Exception e) {
            return Result.error("修改密码失败：" + e.getMessage());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Result<?> updateProfile(Object profile) {
        if (!(profile instanceof Map)) {
            return Result.error("参数格式错误");
        }

        @SuppressWarnings("unchecked")
        Map<String, Object> profileMap = (Map<String, Object>) profile;

        Object userIdObj = profileMap.get("userId");
        Object accountTypeObj = profileMap.get("accountType");

        if (userIdObj == null || accountTypeObj == null) {
            return Result.error("用户信息缺失");
        }

        Long userId = Long.valueOf(userIdObj.toString());
        String accountType = accountTypeObj.toString();

        if ("sys".equals(accountType)) {
            SysUser user = sysUserMapper.selectById(userId);
            if (user == null) {
                return Result.error("用户不存在");
            }

            if (profileMap.containsKey("realName")) {
                user.setRealName(profileMap.get("realName").toString());
            }

            user.setUpdateTime(DateUtil.now());
            sysUserMapper.updateById(user);

            return Result.success("修改成功");
        } else if ("company".equals(accountType)) {
            CompanyUser user = companyUserMapper.selectById(userId);
            if (user == null) {
                return Result.error("用户不存在");
            }

            if (profileMap.containsKey("name")) {
                user.setName(profileMap.get("name").toString());
            }
            if (profileMap.containsKey("mobile")) {
                user.setMobile(profileMap.get("mobile").toString());
            }
            if (profileMap.containsKey("email")) {
                user.setEmail(profileMap.get("email").toString());
            }

            user.setUpdateTime(DateUtil.now());
            companyUserMapper.updateById(user);

            return Result.success("修改成功");
        } else {
            return Result.error("无效的账户类型");
        }
    }

    private Result<?> changeSysUserPassword(Long userId, ChangePasswordDTO dto) {
        SysUser user = sysUserMapper.selectById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }

        if (!passwordMatches(user.getPassword(), dto.getOldPassword())) {
            return Result.error("旧密码错误");
        }

        String encryptedPassword = PasswordUtil.encrypt(dto.getNewPassword());

        String now = DateUtil.now();
        int rows = sysUserMapper.updatePassword(userId, encryptedPassword, now);

        if (rows > 0) {
            return Result.success("密码修改成功");
        } else {
            return Result.error("密码修改失败");
        }
    }

    private Result<?> changeCompanyUserPassword(Long userId, ChangePasswordDTO dto) {
        CompanyUser user = companyUserMapper.selectById(userId);
        if (user == null) {
            return Result.error("用户不存在");
        }

        if (!passwordMatches(user.getPassword(), dto.getOldPassword())) {
            return Result.error("旧密码错误");
        }

        String encryptedPassword = PasswordUtil.encrypt(dto.getNewPassword());

        String now = DateUtil.now();
        int rows = companyUserMapper.updatePassword(userId, encryptedPassword, now);

        if (rows > 0) {
            return Result.success("密码修改成功");
        } else {
            return Result.error("密码修改失败");
        }
    }

    private Result<?> loginSystemUser(SysUser user, String password) {
        if (!passwordMatches(user.getPassword(), password)) {
            return Result.error("password incorrect");
        }
        if (user.getStatus() == 0) {
            return Result.error("account disabled");
        }

        List<String> roleCodes = normalizeRoleCodes(userRoleMapper.selectRoleCodesByUserId(user.getId()));
        if (roleCodes.isEmpty()) {
            roleCodes.add(resolveDefaultRoleCode(user));
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("username", user.getUsername());
        claims.put("accountType", "sys");
        claims.put("roleCodes", roleCodes);
        String token = JwtUtil.createToken(claims);

        String now = DateUtil.now();
        sysUserMapper.updateLastLoginTime(user.getId(), now, now);

        // 构建符合文档的用户信息
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", String.valueOf(user.getId()));
        userInfo.put("username", user.getUsername());
        userInfo.put("realName", user.getRealName());
        userInfo.put("role", convertToRoleCode(user));
        userInfo.put("roleName", convertToRoleName(user));
        userInfo.put("districtCode", user.getRegionId() != null ? String.valueOf(user.getRegionId()) : "");
        userInfo.put("districtName", resolveDistrictName(user.getRegionId()));
        userInfo.put("status", user.getStatus() == 1 ? "启用" : "禁用");
        userInfo.put("createTime", user.getCreateTime() != null ? user.getCreateTime().substring(0, 10) : "");
        userInfo.put("lastLoginTime", now.substring(0, 10));

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("user", userInfo);
        
        return Result.success(result);
    }

    private Result<?> loginCompanyUser(CompanyUser user, String password) {
        if (!passwordMatches(user.getPassword(), password)) {
            return Result.error("password incorrect");
        }
        if (user.getStatus() == 0) {
            return Result.error("account disabled");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("companyId", user.getCompanyId());
        claims.put("username", user.getUsername());
        claims.put("accountType", "company");
        String token = JwtUtil.createToken(claims);

        String now = DateUtil.now();
        companyUserMapper.updateLastLoginTime(user.getId(), now, now);

        // 构建符合文档的用户信息
        Map<String, Object> userInfo = new HashMap<>();
        userInfo.put("id", String.valueOf(user.getId()));
        userInfo.put("username", user.getUsername());
        userInfo.put("realName", user.getName());
        userInfo.put("role", "UNIT");
        userInfo.put("status", user.getStatus() == 1 ? "启用" : "禁用");
        userInfo.put("createTime", user.getCreateTime() != null ? user.getCreateTime().substring(0, 10) : "");

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("user", userInfo);
        
        return Result.success(result);
    }

    private boolean passwordMatches(String savedPassword, String rawPassword) {
        if (savedPassword == null) {
            return false;
        }
        return savedPassword.equals(rawPassword) || savedPassword.equals(PasswordUtil.encrypt(rawPassword));
    }

    private String convertToRoleCode(SysUser user) {
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
            default: return "管理员";
        }
    }

    private String resolveDistrictName(Long regionId) {
        if (regionId == null) return "全市";
        // 这里可以根据regionId查询地区名称，暂时返回简化版
        if (regionId == 510104) return "锦江区";
        if (regionId == 510105) return "青羊区";
        if (regionId == 510106) return "金牛区";
        if (regionId == 510107) return "武侯区";
        if (regionId == 510108) return "成华区";
        return "未知区域";
    }

    private String resolveDataScope(SysUser user) {
        if (user.getUserType() != null && user.getUserType() == 2) {
            return user.getRegionId() == null ? "CITY" : "DISTRICT";
        }
        if (user.getAdminLevel() == null) {
            return "SYSTEM";
        }
        if (user.getAdminLevel() == 1 || user.getAdminLevel() == 2) {
            return "CITY";
        }
        return "DISTRICT";
    }

    private List<String> buildMenus(List<String> roleCodes, Integer userType) {
        if (userType != null && userType == 2) {
            return List.of("dashboard", "statisticsReport", "fundUsageSupervision", "notice");
        }

        List<String> menus = new ArrayList<>();
        menus.add("dashboard");
        if (roleCodes.stream().anyMatch(code -> code.contains("system") || code.contains("admin"))) {
            menus.add("systemManage");
            menus.add("rolePermission");
            menus.add("region");
            menus.add("importCenter");
        }
        menus.add("companyArchive");
        menus.add("employeeManage");
        menus.add("calculation");
        menus.add("paymentVerify");
        menus.add("reductionAudit");
        menus.add("notice");
        menus.add("statisticsReport");
        return menus;
    }

    private List<String> normalizeRoleCodes(List<String> dbRoleCodes) {
        List<String> normalized = new ArrayList<>();
        if (dbRoleCodes == null) {
            return normalized;
        }

        for (String code : dbRoleCodes) {
            if (code == null || code.trim().isEmpty()) {
                continue;
            }
            String raw = code.trim();
            switch (raw) {
                case "SYSTEM_ADMIN":
                    normalized.add("admin_system");
                    break;
                case "CITY_ADMIN":
                    normalized.add("admin_city");
                    break;
                case "DISTRICT_ADMIN":
                    normalized.add("admin_district");
                    break;
                case "CITY_LEADER":
                case "DISTRICT_LEADER":
                    normalized.add("leader");
                    break;
                case "UNIT":
                    normalized.add("company_user");
                    break;
                default:
                    normalized.add(raw);
                    break;
            }
        }
        return normalized;
    }

    private String resolveDefaultRoleCode(SysUser user) {
        if (user.getUserType() != null && user.getUserType() == 2) {
            return "leader";
        }
        if (user.getAdminLevel() != null) {
            switch (user.getAdminLevel()) {
                case 1:
                    return "admin_system";
                case 2:
                    return "admin_city";
                case 3:
                    return "admin_district";
                default:
                    return "admin_system";
            }
        }
        return "admin_system";
    }
}

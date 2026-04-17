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

        List<String> roleCodes = userRoleMapper.selectRoleCodesByUserId(user.getId());
        if (roleCodes == null) {
            roleCodes = new ArrayList<>();
        }
        if (roleCodes.isEmpty()) {
            roleCodes.add(user.getUserType() != null && user.getUserType() == 2 ? "leader_default" : "admin_default");
        }

        Map<String, Object> claims = new HashMap<>();
        claims.put("userId", user.getId());
        claims.put("username", user.getUsername());
        claims.put("accountType", "sys");
        claims.put("roleCodes", roleCodes);
        String token = JwtUtil.createToken(claims);

        String now = DateUtil.now();
        sysUserMapper.updateLastLoginTime(user.getId(), now, now);

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("accountType", "sys");
        result.put("userId", user.getId());
        result.put("username", user.getUsername());
        result.put("realName", user.getRealName());
        result.put("roleCodes", roleCodes);
        result.put("dataScope", resolveDataScope(user));
        result.put("menus", buildMenus(roleCodes, user.getUserType()));
        result.put("readOnly", user.getUserType() != null && user.getUserType() == 2);
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

        Map<String, Object> result = new HashMap<>();
        result.put("token", token);
        result.put("accountType", "company");
        result.put("userId", user.getId());
        result.put("companyId", user.getCompanyId());
        result.put("username", user.getUsername());
        result.put("realName", user.getName());
        result.put("roleCodes", List.of("company_user"));
        result.put("dataScope", "COMPANY");
        result.put("menus", List.of("companyArchive", "employeeManage", "reductionApply", "notice"));
        result.put("readOnly", false);
        return Result.success(result);
    }

    private boolean passwordMatches(String savedPassword, String rawPassword) {
        if (savedPassword == null) {
            return false;
        }
        return savedPassword.equals(rawPassword) || savedPassword.equals(PasswordUtil.encrypt(rawPassword));
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
}

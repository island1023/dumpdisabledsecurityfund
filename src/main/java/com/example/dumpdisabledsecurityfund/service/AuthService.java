package com.example.dumpdisabledsecurityfund.service;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ChangePasswordDTO;
import com.example.dumpdisabledsecurityfund.dto.LoginDTO;

public interface AuthService {
    Result<?> captcha();
    Result<?> login(LoginDTO dto);

    /**
     * 修改密码
     * @param userId 用户ID
     * @param accountType 账户类型：sys/company
     * @param dto 修改密码信息
     * @return 修改结果
     */
    Result<?> changePassword(Long userId, String accountType, ChangePasswordDTO dto);

    /**
     * 修改个人信息
     * @param profile 用户信息
     * @return 修改结果
     */
    Result<?> updateProfile(Object profile);
}

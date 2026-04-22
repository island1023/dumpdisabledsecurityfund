package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 修改密码DTO
 */
@Data
public class ChangePasswordDTO {

    /** 旧密码(必填) */
    @NotBlank(message = "旧密码不能为空")
    private String oldPassword;

    /** 新密码(必填，至少6位) */
    @NotBlank(message = "新密码不能为空")
    private String newPassword;

    /** 确认新密码(必填) */
    @NotBlank(message = "确认密码不能为空")
    private String confirmPassword;
}

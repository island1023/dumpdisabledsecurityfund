package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

/**
 * 登录请求DTO
 */
@Data
public class LoginDTO {

    /** 用户名(必填，登录账号) */
    @NotBlank(message = "用户名不能为空")
    private String username;

    /** 密码(必填) */
    @NotBlank(message = "密码不能为空")
    private String password;

    /** 验证码Key(必填，从获取验证码接口返回) */
    @NotBlank(message = "验证码Key不能为空")
    private String captchaKey;

    /** 验证码(必填，用户输入的图片中的数字) */
    @NotBlank(message = "验证码不能为空")
    private String captchaCode;

    /** 账户类型：sys/company（可选，不传时按兼容逻辑识别） */
    private String accountType;
}

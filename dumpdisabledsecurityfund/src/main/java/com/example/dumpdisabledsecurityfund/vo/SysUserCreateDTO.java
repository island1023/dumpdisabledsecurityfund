package com.example.dumpdisabledsecurityfund.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class SysUserCreateDTO {
    @NotBlank(message = "用户名不能为空")
    private String username;

    @NotBlank(message = "真实姓名不能为空")
    private String realName;

    @NotBlank(message = "角色编码不能为空")
    private String role;

    private String district;
}

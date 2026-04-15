package com.example.dumpdisabledsecurityfund.service;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.LoginDTO;

public interface AuthService {
    Result<?> captcha();
    Result<?> login(LoginDTO dto);
}

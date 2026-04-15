package com.example.dumpdisabledsecurityfund.exception;

import com.example.dumpdisabledsecurityfund.common.GlobalException;

public class BusinessException extends GlobalException {

    public BusinessException(String message) {
        super(500, message);
    }

    public BusinessException(Integer code, String message) {
        super(code, message);
    }
}

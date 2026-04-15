package com.example.dumpdisabledsecurityfund.service;
import com.example.dumpdisabledsecurityfund.common.Result;
import org.springframework.web.multipart.MultipartFile;

public interface PaymentService {
    Result<?> importTaxData(MultipartFile file);
}
package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import org.springframework.web.multipart.MultipartFile;

public interface UploadService {
    /**
     * 上传文件
     * @param file 文件对象
     * @param type 文件类型（certificate/attachment/excel等）
     * @return 上传结果，包含文件URL、文件名、文件大小
     */
    Result<?> uploadFile(MultipartFile file, String type);
}


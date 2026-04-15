package com.example.dumpdisabledsecurityfund.service;

import jakarta.servlet.http.HttpServletResponse;

import java.util.List;

public interface NoticeService {

    void downloadNotice(Long id, HttpServletResponse response);

    void downloadNotices(List<Long> ids, HttpServletResponse response);
}

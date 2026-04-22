package com.example.dumpdisabledsecurityfund.service;

import com.example.dumpdisabledsecurityfund.common.Result;
import jakarta.servlet.http.HttpServletResponse;

import java.util.List;

public interface NoticeService {
    void downloadNotice(Long id, HttpServletResponse response);

    void downloadNotices(List<Long> ids, HttpServletResponse response);

    Result<?> getNotices(Integer page, Integer pageSize, Boolean unreadOnly);

    Result<?> getNoticeDetail(Long noticeId);

    Result<?> markAsRead(Long noticeId);
}


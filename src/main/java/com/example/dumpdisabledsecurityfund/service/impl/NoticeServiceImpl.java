package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.Notice;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.NoticeMapper;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import com.example.dumpdisabledsecurityfund.util.PdfUtil;
import com.example.dumpdisabledsecurityfund.vo.NoticeDetailVO;
import com.example.dumpdisabledsecurityfund.vo.NoticeListVO;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.io.OutputStream;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class NoticeServiceImpl implements NoticeService {
    @Resource
    private NoticeMapper noticeMapper;
    @Resource
    private CompanyMapper companyMapper;

    @Override
    public Result<?> getNotices(Integer page, Integer pageSize, Boolean unreadOnly) {
        if (page == null || page < 1) page = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;

        Long companyId = getCurrentCompanyId();
        if (companyId == null) {
            return Result.error("未登录或不是企业用户");
        }

        int offset = (page - 1) * pageSize;
        List<Notice> notices = noticeMapper.selectByCompanyIdWithPage(companyId, offset, pageSize, unreadOnly);
        long total = noticeMapper.countByCompanyId(companyId, unreadOnly);

        List<NoticeListVO> voList = notices.stream().map(this::convertToListVO).collect(Collectors.toList());
        PageResult<NoticeListVO> pageResult = PageResult.build(total, page, pageSize, voList);

        return Result.success(pageResult);
    }

    @Override
    public Result<?> getNoticeDetail(Long noticeId) {
        Notice notice = noticeMapper.selectById(noticeId);
        if (notice == null) {
            return Result.error("通知单不存在");
        }

        Company company = companyMapper.selectById(notice.getCompanyId());

        NoticeDetailVO vo = new NoticeDetailVO();
        BeanUtils.copyProperties(notice, vo);

        if (company != null) {
            vo.setCompanyName(company.getName());
        }

        vo.setNoticeTypeName(getNoticeTypeName(notice.getNoticeType()));
        vo.setSendStatusName(getSendStatusName(notice.getSendStatus()));

        return Result.success(vo);
    }

    @Override
    public Result<?> markAsRead(Long noticeId) {
        Notice notice = noticeMapper.selectById(noticeId);
        if (notice == null) {
            return Result.error("通知单不存在");
        }

        noticeMapper.updateSendStatus(noticeId, 1);

        return Result.success("操作成功");
    }

    @Override
    public void downloadNotice(Long id, HttpServletResponse response) {
        try {
            Notice notice = noticeMapper.selectById(id);
            if (notice == null) {
                response.sendError(404, "notice not found");
                return;
            }
            Company company = companyMapper.selectById(notice.getCompanyId());
            if (company == null) {
                response.sendError(404, "company not found");
                return;
            }
            PdfUtil.generateNoticePdf(notice, company, response);
        } catch (Exception e) {
            throw new RuntimeException("download notice failed", e);
        }
    }

    @Override
    public void downloadNotices(List<Long> ids, HttpServletResponse response) {
        if (ids == null || ids.isEmpty()) {
            throw new RuntimeException("ids is empty");
        }
        try {
            List<Notice> notices = noticeMapper.selectByIds(ids);
            response.setContentType("application/zip");
            response.setHeader("Content-Disposition", "attachment; filename=notices.zip");
            OutputStream out = response.getOutputStream();
            ZipOutputStream zip = new ZipOutputStream(out);
            for (Notice notice : notices) {
                Company company = companyMapper.selectById(notice.getCompanyId());
                if (company == null) {
                    continue;
                }
                byte[] pdf = PdfUtil.generateNoticePdfBytes(notice, company);
                zip.putNextEntry(new ZipEntry("notice_" + notice.getId() + ".pdf"));
                zip.write(pdf);
                zip.closeEntry();
            }
            zip.finish();
            zip.close();
            out.close();
        } catch (Exception e) {
            throw new RuntimeException("download notices failed", e);
        }
    }

    private Long getCurrentCompanyId() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }

        HttpServletRequest request = attributes.getRequest();
        Object companyIdObj = request.getAttribute("companyId");

        if (companyIdObj == null) {
            return null;
        }

        return Long.valueOf(companyIdObj.toString());
    }

    private NoticeListVO convertToListVO(Notice notice) {
        NoticeListVO vo = new NoticeListVO();
        BeanUtils.copyProperties(notice, vo);

        Company company = companyMapper.selectById(notice.getCompanyId());
        if (company != null) {
            vo.setCompanyName(company.getName());
        }

        vo.setNoticeTypeName(getNoticeTypeName(notice.getNoticeType()));
        vo.setSendStatusName(getSendStatusName(notice.getSendStatus()));

        return vo;
    }

    private String getNoticeTypeName(Integer type) {
        if (type == null) return "";
        switch (type) {
            case 1: return "缴款通知书";
            case 2: return "征收决定书";
            case 3: return "催缴提醒函";
            case 4: return "数据核对通知";
            default: return "未知";
        }
    }

    private String getSendStatusName(Integer status) {
        if (status == null) return "";
        switch (status) {
            case 0: return "未送达";
            case 1: return "已送达";
            case 2: return "退回";
            default: return "未知";
        }
    }
}


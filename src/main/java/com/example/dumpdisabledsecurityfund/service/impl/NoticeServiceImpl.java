package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.Notice;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.NoticeMapper;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import com.example.dumpdisabledsecurityfund.util.PdfUtil;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Service;

import java.io.OutputStream;
import java.util.List;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;

@Service
public class NoticeServiceImpl implements NoticeService {
    @Resource
    private NoticeMapper noticeMapper;
    @Resource
    private CompanyMapper companyMapper;

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
}

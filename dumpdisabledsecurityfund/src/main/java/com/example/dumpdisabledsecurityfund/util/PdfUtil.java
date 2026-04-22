package com.example.dumpdisabledsecurityfund.util;

import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.Notice;
import com.itextpdf.text.Document;
import com.itextpdf.text.Font;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.pdf.BaseFont;
import com.itextpdf.text.pdf.PdfWriter;

import jakarta.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.OutputStream;

public class PdfUtil {

    public static void generateNoticePdf(Notice notice, Company company, HttpServletResponse response) throws Exception {
        generateNoticePdf(notice, company, response, true);
    }

    public static void generateNoticePdf(Notice notice, Company company, HttpServletResponse response, boolean asAttachment) throws Exception {
        byte[] bytes = generateNoticePdfBytes(notice, company);
        response.setContentType("application/pdf");
        String disposition = asAttachment ? "attachment" : "inline";
        response.setHeader("Content-Disposition", disposition + "; filename=notice_" + notice.getId() + ".pdf");
        response.setHeader("Content-Length", String.valueOf(bytes.length));
        response.setHeader("Cache-Control", "no-store");
        OutputStream out = response.getOutputStream();
        out.write(bytes);
        out.flush();
        out.close();
    }

    public static byte[] generateNoticePdfBytes(Notice notice, Company company) throws Exception {
        ByteArrayOutputStream out = new ByteArrayOutputStream();
        Document document = new Document();
        PdfWriter.getInstance(document, out);
        document.open();

        Font titleFont = createTitleFont();
        Font bodyFont = createBodyFont();

        document.add(new Paragraph("残疾人就业保障金通知书", titleFont));
        document.add(new Paragraph(" ", bodyFont));
        document.add(new Paragraph("通知书编号：" + safe(notice.getNoticeNumber()), bodyFont));
        document.add(new Paragraph("单位名称：" + safe(company.getName()), bodyFont));
        document.add(new Paragraph("统一社会信用代码：" + safe(company.getUnifiedSocialCreditCode()), bodyFont));
        document.add(new Paragraph("通知书类型：" + (notice.getNoticeType() != null && notice.getNoticeType() == 1 ? "缴款通知书" : "征收决定书"), bodyFont));
        document.add(new Paragraph(" ", bodyFont));
        document.add(new Paragraph("通知内容：", bodyFont));
        document.add(new Paragraph(safe(notice.getContent()), bodyFont));
        document.add(new Paragraph(" ", bodyFont));
        document.add(new Paragraph("生成时间：" + DateUtil.now(), bodyFont));

        document.close();
        return out.toByteArray();
    }

    private static Font createTitleFont() {
        try {
            BaseFont baseFont = createChineseBaseFont();
            if (baseFont != null) {
                return new Font(baseFont, 18, Font.BOLD);
            }
        } catch (Exception ignored) {
        }
        return new Font(Font.FontFamily.HELVETICA, 18, Font.BOLD);
    }

    private static Font createBodyFont() {
        try {
            BaseFont baseFont = createChineseBaseFont();
            if (baseFont != null) {
                return new Font(baseFont, 12, Font.NORMAL);
            }
        } catch (Exception ignored) {
        }
        return new Font(Font.FontFamily.HELVETICA, 12, Font.NORMAL);
    }

    private static BaseFont createChineseBaseFont() {
        String[] windowsFonts = new String[] {
                "C:/Windows/Fonts/msyh.ttc,0",   // 微软雅黑
                "C:/Windows/Fonts/simsun.ttc,0", // 宋体
                "C:/Windows/Fonts/simhei.ttf"    // 黑体
        };
        for (int i = 0; i < windowsFonts.length; i++) {
            try {
                return BaseFont.createFont(windowsFonts[i], BaseFont.IDENTITY_H, BaseFont.NOT_EMBEDDED);
            } catch (Exception ignored) {
            }
        }
        try {
            return BaseFont.createFont("STSong-Light", "UniGB-UCS2-H", BaseFont.NOT_EMBEDDED);
        } catch (Exception ignored) {
            return null;
        }
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}

package com.example.dumpdisabledsecurityfund.util;

import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.Notice;
import com.itextpdf.text.Document;
import com.itextpdf.text.Paragraph;
import com.itextpdf.text.pdf.PdfWriter;

import jakarta.servlet.http.HttpServletResponse;
import java.io.ByteArrayOutputStream;
import java.io.OutputStream;

public class PdfUtil {

    public static void generateNoticePdf(Notice notice, Company company, HttpServletResponse response) throws Exception {
        byte[] bytes = generateNoticePdfBytes(notice, company);
        response.setContentType("application/pdf");
        response.setHeader("Content-Disposition", "attachment; filename=notice_" + notice.getId() + ".pdf");
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

        document.add(new Paragraph("Disabled Employment Security Fund Notice"));
        document.add(new Paragraph(" "));
        document.add(new Paragraph("Notice No: " + safe(notice.getNoticeNumber())));
        document.add(new Paragraph("Company: " + safe(company.getName())));
        document.add(new Paragraph("Credit Code: " + safe(company.getUnifiedSocialCreditCode())));
        document.add(new Paragraph("Notice Type: " + (notice.getNoticeType() != null && notice.getNoticeType() == 1 ? "Payment Notice" : "Collection Decision")));
        document.add(new Paragraph(" "));
        document.add(new Paragraph("Content: "));
        document.add(new Paragraph(safe(notice.getContent())));
        document.add(new Paragraph(" "));
        document.add(new Paragraph("Generated At: " + DateUtil.now()));

        document.close();
        return out.toByteArray();
    }

    private static String safe(String value) {
        return value == null ? "" : value;
    }
}

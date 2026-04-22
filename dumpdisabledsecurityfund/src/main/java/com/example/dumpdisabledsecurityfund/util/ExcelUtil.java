package com.example.dumpdisabledsecurityfund.util;

import org.apache.poi.ss.usermodel.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.text.DecimalFormat;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.List;

public class ExcelUtil {

    public static List<List<String>> readExcel(MultipartFile file) throws Exception {
        System.out.println("=== ExcelUtil.readExcel 开始执行 ===");
        System.out.println("=== 原始文件名: " + file.getOriginalFilename());

        List<List<String>> result = new ArrayList<>();
        InputStream inputStream = null;
        Workbook workbook = null;

        try {
            inputStream = file.getInputStream();
            System.out.println("=== 文件输入流获取成功 ===");

            workbook = WorkbookFactory.create(inputStream);
            System.out.println("=== Workbook创建成功 ===");

            Sheet sheet = workbook.getSheetAt(0);
            System.out.println("=== 获取第一个工作表: " + sheet.getSheetName());
            System.out.println("=== 最后一行号: " + sheet.getLastRowNum());

            for (int i = 1; i <= sheet.getLastRowNum(); i++) {
                Row row = sheet.getRow(i);
                if (row == null) {
                    System.out.println("=== 第 " + (i + 1) + " 行为空，跳过 ===");
                    continue;
                }

                List<String> rowData = new ArrayList<>();
                for (Cell cell : row) {
                    String value = getCellValue(cell);
                    rowData.add(value);
                }
                result.add(rowData);
                System.out.println("=== 读取第 " + (i + 1) + " 行，共 " + rowData.size() + " 列: " + rowData + " ===");
            }

            System.out.println("=== Excel读取完成，共读取 " + result.size() + " 行有效数据 ===");
            return result;
        } catch (Exception e) {
            System.out.println("=== Excel读取失败: " + e.getClass().getName() + " - " + e.getMessage() + " ===");
            e.printStackTrace();
            throw e;
        } finally {
            if (workbook != null) {
                try {
                    workbook.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
            if (inputStream != null) {
                try {
                    inputStream.close();
                } catch (Exception e) {
                    e.printStackTrace();
                }
            }
        }
    }

    private static String getCellValue(Cell cell) {
        if (cell == null) {
            return "";
        }

        CellType cellType = cell.getCellType();

        switch (cellType) {
            case STRING:
                return cell.getStringCellValue().trim();

            case NUMERIC:
                if (org.apache.poi.ss.usermodel.DateUtil.isCellDateFormatted(cell)) {
                    SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd");
                    return sdf.format(cell.getDateCellValue());
                } else {
                    DecimalFormat df = new DecimalFormat("0");
                    return df.format(cell.getNumericCellValue());
                }

            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());

            case FORMULA:
                try {
                    return cell.getStringCellValue().trim();
                } catch (Exception e) {
                    return String.valueOf(cell.getNumericCellValue());
                }

            case BLANK:
                return "";

            default:
                return "";
        }
    }
}

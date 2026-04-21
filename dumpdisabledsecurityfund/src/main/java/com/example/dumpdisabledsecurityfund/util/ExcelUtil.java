package com.example.dumpdisabledsecurityfund.util;

import org.apache.poi.ss.usermodel.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;

public class ExcelUtil {
    public static List<List<String>> readExcel(MultipartFile file) throws Exception {
        List<List<String>> result = new ArrayList<>();
        InputStream inputStream = file.getInputStream();
        Workbook workbook = WorkbookFactory.create(inputStream);
        Sheet sheet = workbook.getSheetAt(0);

        for (int i = 1; i <= sheet.getLastRowNum(); i++) {
            Row row = sheet.getRow(i);
            if (row == null) continue;

            List<String> rowData = new ArrayList<>();
            for (Cell cell : row) {
                cell.setCellType(CellType.STRING);
                rowData.add(cell.getStringCellValue().trim());
            }
            result.add(rowData);
        }
        workbook.close();
        inputStream.close();
        return result;
    }
}
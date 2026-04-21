package com.example.dumpdisabledsecurityfund.vo;

import lombok.Data;
import java.util.List;

@Data
public class ApplicationProgressVO {
    private String currentStep;
    private List<ProgressStep> steps;
    private String message;

    @Data
    public static class ProgressStep {
        private String title;
        private String status;
        private String time;
    }
}

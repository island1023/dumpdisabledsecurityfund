package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.CompanyReduction;
import com.example.dumpdisabledsecurityfund.entity.FundUsage;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.entity.PaymentRecord;
import com.example.dumpdisabledsecurityfund.entity.Region;
import com.example.dumpdisabledsecurityfund.mapper.CompanyDisabledEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyEmployeeMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.CompanyReductionMapper;
import com.example.dumpdisabledsecurityfund.mapper.FundUsageMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.mapper.PaymentRecordMapper;
import com.example.dumpdisabledsecurityfund.mapper.RegionMapper;
import com.example.dumpdisabledsecurityfund.service.LeaderService;
import jakarta.annotation.Resource;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
@Service
public class LeaderServiceImpl implements LeaderService {

    @Resource
    private CompanyMapper companyMapper;
    @Resource
    private RegionMapper regionMapper;
    @Resource
    private CompanyEmployeeMapper companyEmployeeMapper;
    @Resource
    private CompanyDisabledEmployeeMapper companyDisabledEmployeeMapper;
    @Resource
    private PayableAmountMapper payableAmountMapper;
    @Resource
    private PaymentRecordMapper paymentRecordMapper;
    @Resource
    private CompanyReductionMapper companyReductionMapper;
    @Resource
    private FundUsageMapper fundUsageMapper;

    @Override
    public Result<?> listArchiveCompanies(String keyword, Integer pageNum, Integer pageSize) {
        if (pageNum == null || pageNum < 1) {
            pageNum = 1;
        }
        if (pageSize == null || pageSize < 1) {
            pageSize = 20;
        }
        Long regionScope = resolveLeaderRegionScope();
        int offset = (pageNum - 1) * pageSize;
        List<Company> companies = companyMapper.selectCompaniesWithPageForLeader(keyword, regionScope, offset, pageSize);
        long total = companyMapper.countCompaniesForLeader(keyword, regionScope);

        List<Map<String, Object>> rows = new ArrayList<>();
        for (Company c : companies) {
            rows.add(buildArchiveListRow(c));
        }
        PageResult<Map<String, Object>> page = PageResult.build(total, pageNum, pageSize, rows);
        return Result.success(page);
    }

    @Override
    public Result<?> getArchiveCompanyDetail(Long companyId) {
        Company company = companyMapper.selectById(companyId);
        if (company == null) {
            return Result.error("单位不存在");
        }
        Long regionScope = resolveLeaderRegionScope();
        if (regionScope != null && company.getRegionId() != null && !regionScope.equals(company.getRegionId())) {
            return Result.forbidden("无权查看该单位档案");
        }

        Map<String, Object> detail = new HashMap<>();
        detail.put("id", String.valueOf(company.getId()));
        detail.put("companyName", nz(company.getName()));
        detail.put("creditCode", nz(company.getUnifiedSocialCreditCode()));
        detail.put("legalPerson", nz(company.getLegalPerson()));
        detail.put("registerAddress", nz(company.getAddress()));
        detail.put("establishDate", nz(company.getEstablishDate()));
        detail.put("phone", nz(company.getContactPhone()));
        detail.put("industry", nz(company.getIndustry()));

        int totalEmp = resolveCompanyTotalEmployees(company, companyId);
        int disabledEmp = (int) companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);
        detail.put("employeeCount", totalEmp);
        detail.put("disabledCount", disabledEmp);

        String district = "";
        if (company.getRegionId() != null) {
            Region r = regionMapper.selectById(company.getRegionId());
            if (r != null) {
                district = nz(r.getName());
            }
        }
        detail.put("district", district);

        List<PayableAmount> payables = payableAmountMapper.selectByCompanyId(companyId);
        int maxYear = java.time.Year.now().getValue();
        if (payables != null && !payables.isEmpty()) {
            maxYear = payables.stream().map(PayableAmount::getYear).max(Integer::compareTo).orElse(maxYear);
        }
        detail.put("collectionYear", maxYear + "年");

        List<Map<String, Object>> paymentRows = new ArrayList<>();
        if (payables != null) {
            for (PayableAmount pa : payables) {
                Map<String, Object> row = new HashMap<>();
                row.put("year", pa.getYear() + "年");
                double payableAmt = resolvePayableAmount(pa);
                double paidAmt = pa.getPaidAmount() != null ? pa.getPaidAmount() : 0;
                row.put("payableAmount", payableAmt);
                row.put("paidAmount", paidAmt);
                row.put("status", mapPaymentStatus(pa.getPaymentStatus()));
                row.put("payDate", findLatestPaymentDate(pa.getId()));
                paymentRows.add(row);
            }
        }
        detail.put("paymentRecords", paymentRows);

        List<Map<String, Object>> reliefRows = new ArrayList<>();
        List<CompanyReduction> reductions = companyReductionMapper.selectByCompanyId(companyId);
        if (reductions != null) {
            for (CompanyReduction cr : reductions) {
                Map<String, Object> r = new HashMap<>();
                r.put("type", mapApplyType(cr.getApplyType()));
                r.put("reason", nz(cr.getReason()));
                Map<String, String> period = resolveReductionPeriod(cr);
                r.put("startDate", period.getOrDefault("startDate", ""));
                r.put("endDate", period.getOrDefault("endDate", ""));
                r.put("amount", cr.getApplyAmount() != null ? cr.getApplyAmount() : 0);
                r.put("status", mapAuditStatus(cr.getAuditStatus()));
                reliefRows.add(r);
            }
        }
        detail.put("reliefStatuses", reliefRows);

        return Result.success(detail);
    }

    @Override
    public Result<?> listFundUsage(String keyword, String projectType) {
        Long regionScope = resolveLeaderRegionScope();
        String kw = keyword != null && !keyword.isBlank() ? keyword.trim() : null;
        String pt = projectType != null && !projectType.isBlank() && !"all".equalsIgnoreCase(projectType)
                ? projectType.trim() : null;

        List<FundUsage> list = fundUsageMapper.selectLeaderFundUsage(regionScope, pt, kw);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (FundUsage fu : list) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", String.valueOf(fu.getId()));
            m.put("projectName", nz(fu.getProjectName()));
            m.put("projectType", nz(fu.getProjectType()));
            m.put("district", resolveRegionName(fu.getRegionId()));
            m.put("amount", fu.getAmount() != null ? fu.getAmount() : 0);
            m.put("usageDate", extractDate(fu.getUsageDate()));
            m.put("status", resolveUsageStatus(fu));
            m.put("description", nz(fu.getDescription()));
            m.put("beneficiaryCount", fu.getBeneficiaryCount() != null ? fu.getBeneficiaryCount() : 0);
            rows.add(m);
        }
        return Result.success(rows);
    }

    @Override
    public Result<?> listExternalReportRows(String reportType, Integer year, Integer month) {
        if (reportType == null || reportType.isBlank()) {
            return Result.error("报表类型不能为空");
        }
        int y = year != null ? year : java.time.Year.now().getValue();
        int m = month != null ? month : java.time.MonthDay.now().getMonthValue();
        String normalizedType = reportType.trim();
        Long regionScope = resolveLeaderRegionScope();
        List<Map<String, Object>> out;

        if ("UNIT_INFO".equalsIgnoreCase(normalizedType)) {
            out = buildRealtimeUnitInfoRows(regionScope);
        } else if ("UNPAID_UNIT".equalsIgnoreCase(normalizedType)) {
            out = buildRealtimeUnpaidUnitRows(regionScope, y, m);
        } else if ("PAYMENT_STAT".equalsIgnoreCase(normalizedType)) {
            out = buildRealtimePaymentStatRows(regionScope, y);
        } else if ("RELIEF_STAT".equalsIgnoreCase(normalizedType)) {
            out = buildRealtimeReliefStatRows(regionScope, y);
        } else {
            return Result.error("不支持的报表类型: " + normalizedType);
        }
        Map<String, Object> wrap = new HashMap<>();
        wrap.put("year", y);
        wrap.put("month", m);
        wrap.put("reportType", normalizedType);
        wrap.put("rows", out);
        return Result.success(wrap);
    }

    private List<Map<String, Object>> buildRealtimeUnitInfoRows(Long regionScope) {
        List<Company> companies = regionScope == null ? companyMapper.selectAll() : companyMapper.selectByRegionId(regionScope);
        Map<Long, Map<String, Object>> grouped = new HashMap<>();
        for (int i = 0; i < companies.size(); i++) {
            Company c = companies.get(i);
            if (c == null) {
                continue;
            }
            Long regionId = c.getRegionId() == null ? 0L : c.getRegionId();
            Map<String, Object> row = grouped.get(regionId);
            if (row == null) {
                row = new HashMap<>();
                row.put("district", resolveRegionName(c.getRegionId()));
                row.put("unitCount", 0);
                row.put("totalEmployees", 0);
                row.put("disabledEmployees", 0);
                grouped.put(regionId, row);
            }

            int unitCount = ((Number) row.get("unitCount")).intValue();
            int totalEmployees = ((Number) row.get("totalEmployees")).intValue();
            int disabledEmployees = ((Number) row.get("disabledEmployees")).intValue();

            long companyId = c.getId() == null ? 0L : c.getId();
            totalEmployees += resolveCompanyTotalEmployees(c, companyId);
            disabledEmployees += (int) companyDisabledEmployeeMapper.countActiveByCompanyId(companyId);
            unitCount += 1;

            row.put("unitCount", unitCount);
            row.put("totalEmployees", totalEmployees);
            row.put("disabledEmployees", disabledEmployees);
        }

        List<Map<String, Object>> rows = new ArrayList<>(grouped.values());
        rows.sort((a, b) -> {
            String da = String.valueOf(a.get("district"));
            String db = String.valueOf(b.get("district"));
            return da.compareTo(db);
        });
        return rows;
    }

    private List<Map<String, Object>> buildRealtimeUnpaidUnitRows(Long regionScope, int year, int month) {
        List<PayableAmount> payables = payableAmountMapper.selectByYear(year);
        List<Map<String, Object>> rows = new ArrayList<>();
        for (int i = 0; i < payables.size(); i++) {
            PayableAmount pa = payables.get(i);
            if (pa == null) {
                continue;
            }
            if (pa.getPaymentStatus() != null && pa.getPaymentStatus() == 2) {
                continue;
            }
            double payableAmount = resolvePayableAmount(pa);
            if (payableAmount <= 0) {
                continue;
            }
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company == null) {
                continue;
            }
            if (regionScope != null && company.getRegionId() != null && !regionScope.equals(company.getRegionId())) {
                continue;
            }
            Map<String, Object> row = new HashMap<>();
            row.put("companyName", nz(company.getName()));
            row.put("district", resolveRegionName(company.getRegionId()));
            row.put("year", pa.getYear() == null ? String.valueOf(year) : pa.getYear() + "年");
            row.put("payableAmount", payableAmount);
            row.put("unpaidMonths", calculateUnpaidMonths(pa, month));
            rows.add(row);
        }
        return rows;
    }

    private List<Map<String, Object>> buildRealtimePaymentStatRows(Long regionScope, int year) {
        List<PayableAmount> payables = payableAmountMapper.selectByYear(year);
        Map<Long, Map<String, Object>> grouped = new HashMap<>();
        for (int i = 0; i < payables.size(); i++) {
            PayableAmount pa = payables.get(i);
            if (pa == null) {
                continue;
            }
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company == null) {
                continue;
            }
            if (regionScope != null && company.getRegionId() != null && !regionScope.equals(company.getRegionId())) {
                continue;
            }
            Long regionId = company.getRegionId() == null ? 0L : company.getRegionId();
            Map<String, Object> row = grouped.get(regionId);
            if (row == null) {
                row = new HashMap<>();
                row.put("district", resolveRegionName(company.getRegionId()));
                row.put("totalPayable", 0D);
                row.put("totalPaid", 0D);
                grouped.put(regionId, row);
            }
            double totalPayable = ((Number) row.get("totalPayable")).doubleValue();
            double totalPaid = ((Number) row.get("totalPaid")).doubleValue();
            totalPayable += resolvePayableAmount(pa);
            totalPaid += pa.getPaidAmount() == null ? 0D : pa.getPaidAmount();
            row.put("totalPayable", totalPayable);
            row.put("totalPaid", totalPaid);
        }

        List<Map<String, Object>> rows = new ArrayList<>(grouped.values());
        for (int i = 0; i < rows.size(); i++) {
            Map<String, Object> row = rows.get(i);
            double totalPayable = ((Number) row.get("totalPayable")).doubleValue();
            double totalPaid = ((Number) row.get("totalPaid")).doubleValue();
            double paymentRate = totalPayable <= 0 ? 100D : (totalPaid / totalPayable) * 100D;
            if (paymentRate > 100D) {
                paymentRate = 100D;
            }
            row.put("paymentRate", Math.round(paymentRate * 10D) / 10D);
        }
        rows.sort((a, b) -> String.valueOf(a.get("district")).compareTo(String.valueOf(b.get("district"))));
        return rows;
    }

    private List<Map<String, Object>> buildRealtimeReliefStatRows(Long regionScope, int year) {
        List<Company> companies = regionScope == null ? companyMapper.selectAll() : companyMapper.selectByRegionId(regionScope);
        Map<String, Map<String, Object>> grouped = new HashMap<>();
        Map<String, Set<Long>> companySets = new HashMap<>();

        for (int i = 0; i < companies.size(); i++) {
            Company company = companies.get(i);
            if (company == null || company.getId() == null) {
                continue;
            }
            List<CompanyReduction> reductions = companyReductionMapper.selectByCompanyIdAndYear(company.getId(), year);
            if (reductions == null || reductions.isEmpty()) {
                continue;
            }
            for (int j = 0; j < reductions.size(); j++) {
                CompanyReduction cr = reductions.get(j);
                String type = mapApplyType(cr.getApplyType());
                Map<String, Object> row = grouped.get(type);
                if (row == null) {
                    row = new HashMap<>();
                    row.put("type", type);
                    row.put("unitCount", 0);
                    row.put("totalAmount", 0D);
                    row.put("approvedCount", 0);
                    grouped.put(type, row);
                    companySets.put(type, new HashSet<>());
                }
                Set<Long> companySet = companySets.get(type);
                if (!companySet.contains(company.getId())) {
                    companySet.add(company.getId());
                    int unitCount = ((Number) row.get("unitCount")).intValue();
                    row.put("unitCount", unitCount + 1);
                }

                double totalAmount = ((Number) row.get("totalAmount")).doubleValue();
                totalAmount += cr.getApplyAmount() == null ? 0D : cr.getApplyAmount();
                row.put("totalAmount", totalAmount);

                if (cr.getAuditStatus() != null && cr.getAuditStatus() == 1) {
                    int approvedCount = ((Number) row.get("approvedCount")).intValue();
                    row.put("approvedCount", approvedCount + 1);
                }
            }
        }
        List<Map<String, Object>> rows = new ArrayList<>(grouped.values());
        rows.sort((a, b) -> String.valueOf(a.get("type")).compareTo(String.valueOf(b.get("type"))));
        return rows;
    }

    private int calculateUnpaidMonths(PayableAmount payable, int selectedMonth) {
        if (payable == null || payable.getId() == null) {
            return selectedMonth;
        }
        List<PaymentRecord> records = paymentRecordMapper.selectByPayableId(payable.getId());
        int latestPaidMonth = 0;
        for (int i = 0; i < records.size(); i++) {
            PaymentRecord record = records.get(i);
            int month = extractMonth(record.getPaymentDate());
            if (month > latestPaidMonth) {
                latestPaidMonth = month;
            }
        }
        int unpaidMonths = selectedMonth - latestPaidMonth;
        if (unpaidMonths < 1) {
            return 1;
        }
        return unpaidMonths;
    }

    private int extractMonth(String dateTime) {
        if (dateTime == null || dateTime.length() < 7) {
            return 0;
        }
        try {
            return Integer.parseInt(dateTime.substring(5, 7));
        } catch (Exception e) {
            return 0;
        }
    }

    private int resolveCompanyTotalEmployees(Company company, long companyId) {
        if (company != null && company.getEmployeeCount() != null && company.getEmployeeCount() > 0) {
            return company.getEmployeeCount();
        }
        return (int) companyEmployeeMapper.countActiveByCompanyId(companyId);
    }

    private Map<String, Object> buildArchiveListRow(Company c) {
        Map<String, Object> row = new HashMap<>();
        row.put("id", String.valueOf(c.getId()));
        row.put("companyName", nz(c.getName()));
        row.put("creditCode", nz(c.getUnifiedSocialCreditCode()));
        row.put("legalPerson", nz(c.getLegalPerson()));
        row.put("registerAddress", nz(c.getAddress()));
        row.put("establishDate", nz(c.getEstablishDate()));
        row.put("phone", nz(c.getContactPhone()));

        Long cid = c.getId();
        int totalEmp = cid != null ? resolveCompanyTotalEmployees(c, cid) : 0;
        int disabledEmp = cid != null ? (int) companyDisabledEmployeeMapper.countActiveByCompanyId(cid) : 0;
        row.put("employeeCount", totalEmp);
        row.put("disabledCount", disabledEmp);

        String district = "";
        if (c.getRegionId() != null) {
            Region r = regionMapper.selectById(c.getRegionId());
            if (r != null) {
                district = nz(r.getName());
            }
        }
        row.put("district", district);

        List<PayableAmount> payables = cid != null ? payableAmountMapper.selectByCompanyId(cid) : List.of();
        int maxYear = java.time.Year.now().getValue();
        if (!payables.isEmpty()) {
            maxYear = payables.stream().map(PayableAmount::getYear).max(Integer::compareTo).orElse(maxYear);
        }
        row.put("collectionYear", maxYear + "年");
        return row;
    }

    private Long resolveLeaderRegionScope() {
        Map<String, Object> claims = currentClaims();
        if (claims == null) {
            return null;
        }
        if (!isDistrictLeader(claims)) {
            // 市领导默认全市范围；区领导才按 regionId 强制收敛
            return null;
        }
        Object rid = claims.get("regionId");
        if (rid == null) {
            return null;
        }
        if (rid instanceof Number) {
            long v = ((Number) rid).longValue();
            return v > 0 ? v : null;
        }
        try {
            long v = Long.parseLong(rid.toString());
            return v > 0 ? v : null;
        } catch (Exception e) {
            return null;
        }
    }

    private boolean isDistrictLeader(Map<String, Object> claims) {
        if (claims == null) {
            return false;
        }
        Object primaryRole = claims.get("primaryRole");
        if (primaryRole != null && "DISTRICT_LEADER".equals(String.valueOf(primaryRole))) {
            return true;
        }
        Object userType = claims.get("userType");
        Object adminLevel = claims.get("adminLevel");
        String userTypeValue = userType == null ? "" : String.valueOf(userType);
        String adminLevelValue = adminLevel == null ? "" : String.valueOf(adminLevel);
        return "2".equals(userTypeValue) && "3".equals(adminLevelValue);
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> currentClaims() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }
        HttpServletRequest request = attributes.getRequest();
        Object u = request.getAttribute("userInfo");
        if (u instanceof Map) {
            return (Map<String, Object>) u;
        }
        return null;
    }

    private String resolveRegionName(Long regionId) {
        if (regionId == null) {
            return "";
        }
        Region r = regionMapper.selectById(regionId);
        return r != null ? nz(r.getName()) : "";
    }

    private String resolveUsageStatus(FundUsage fu) {
        if (fu.getUsageStatus() != null && !fu.getUsageStatus().isBlank()) {
            return fu.getUsageStatus();
        }
        if (fu.getAuditStatus() != null && fu.getAuditStatus() == 1) {
            return "已拨付";
        }
        if (fu.getAuditStatus() != null && fu.getAuditStatus() == 0) {
            return "拨付中";
        }
        return "待审";
    }

    private double resolvePayableAmount(PayableAmount pa) {
        if (pa.getPayableAmount() != null) {
            return pa.getPayableAmount();
        }
        double calc = pa.getCalculatedAmount() != null ? pa.getCalculatedAmount() : 0;
        double red = pa.getReductionAmount() != null ? pa.getReductionAmount() : 0;
        return Math.max(0, calc - red);
    }

    private String findLatestPaymentDate(Long payableId) {
        List<PaymentRecord> records = paymentRecordMapper.selectByPayableId(payableId);
        if (records == null || records.isEmpty()) {
            return "";
        }
        return extractDate(records.get(0).getPaymentDate());
    }

    private String mapPaymentStatus(Integer paymentStatus) {
        if (paymentStatus == null) {
            return "未缴";
        }
        if (paymentStatus == 2) {
            return "已缴";
        }
        if (paymentStatus == 1) {
            return "部分缴纳";
        }
        return "未缴";
    }

    private String mapApplyType(Integer applyType) {
        if (applyType == null) {
            return "减免";
        }
        return switch (applyType) {
            case 2 -> "免缴";
            case 3 -> "缓缴";
            default -> "减免";
        };
    }

    private String mapAuditStatus(Integer auditStatus) {
        if (auditStatus == null) {
            return "审批中";
        }
        if (auditStatus == 1) {
            return "已通过";
        }
        if (auditStatus == 2) {
            return "已拒绝";
        }
        return "审批中";
    }

    private String extractDate(String dateTime) {
        if (dateTime == null || dateTime.isEmpty()) {
            return "";
        }
        int sp = dateTime.indexOf(' ');
        return sp > 0 ? dateTime.substring(0, sp) : dateTime;
    }

    /**
     * 领导端“期限”按申请年度展示，且保证 start <= end。
     * 例如 year=2025 时默认展示 2025-01-01 至 2025-12-31。
     */
    private Map<String, String> resolveReductionPeriod(CompanyReduction cr) {
        Map<String, String> map = new HashMap<>();
        if (cr == null || cr.getYear() == null) {
            map.put("startDate", extractDate(cr != null ? cr.getCreateTime() : null));
            map.put("endDate", "");
            return map;
        }

        String start = cr.getYear() + "-01-01";
        String end = cr.getYear() + "-12-31";

        // 如果 createTime 正好在申请年度内，则用 createTime 作为更精确的开始日
        String created = extractDate(cr.getCreateTime());
        if (created.length() >= 4) {
            try {
                int createdYear = Integer.parseInt(created.substring(0, 4));
                if (createdYear == cr.getYear()) {
                    start = created;
                }
            } catch (Exception ignored) {
            }
        }

        // 兜底：避免出现 start > end 的倒序
        if (start.compareTo(end) > 0) {
            start = cr.getYear() + "-01-01";
        }

        map.put("startDate", start);
        map.put("endDate", end);
        return map;
    }

    private String nz(String s) {
        return s == null ? "" : s;
    }
}

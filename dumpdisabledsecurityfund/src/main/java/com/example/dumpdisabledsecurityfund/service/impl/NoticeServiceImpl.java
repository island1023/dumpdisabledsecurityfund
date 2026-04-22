package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.PageResult;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.entity.Company;
import com.example.dumpdisabledsecurityfund.entity.Notice;
import com.example.dumpdisabledsecurityfund.entity.PayableAmount;
import com.example.dumpdisabledsecurityfund.mapper.CompanyMapper;
import com.example.dumpdisabledsecurityfund.mapper.NoticeMapper;
import com.example.dumpdisabledsecurityfund.mapper.PayableAmountMapper;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import com.example.dumpdisabledsecurityfund.util.DateUtil;
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
    @Resource
    private PayableAmountMapper payableAmountMapper;

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
    public Result<?> getAdminNoticeList(Integer page, Integer pageSize, Integer year, Integer noticeType, String keyword, Long regionId) {
        if (page == null || page < 1) page = 1;
        if (pageSize == null || pageSize < 1) pageSize = 20;
        int queryYear = year == null ? DateUtil.getCurrentYear() : year;
        int type = noticeType == null ? 1 : noticeType;
        List<PayableAmount> source = filterByRegionScope(payableAmountMapper.selectByYear(queryYear), regionId).stream()
                .filter(pa -> isTargetForCollectionNotice(pa, type))
                .collect(Collectors.toList());

        // 未显式传 year 时，若当前年无数据，则回退到最近有数据的年度
        if (year == null && source.isEmpty()) {
            Integer fallbackYear = resolveLatestAvailableYear(regionId, type);
            if (fallbackYear != null && fallbackYear > 0 && fallbackYear != queryYear) {
                queryYear = fallbackYear;
                source = filterByRegionScope(payableAmountMapper.selectByYear(queryYear), regionId).stream()
                        .filter(pa -> isTargetForCollectionNotice(pa, type))
                        .collect(Collectors.toList());
            }
        }
        List<Map<String, Object>> rows = source.stream()
                .map(pa -> buildAdminNoticeRow(pa, type))
                .filter(item -> item != null)
                .collect(Collectors.toList());

        if (keyword != null && !keyword.trim().isEmpty()) {
            String kw = keyword.trim().toLowerCase();
            rows = rows.stream().filter(item -> String.valueOf(item.get("companyName")).toLowerCase().contains(kw)).collect(Collectors.toList());
        }
        int total = rows.size();
        int start = (page - 1) * pageSize;
        int end = Math.min(start + pageSize, total);
        List<Map<String, Object>> list = start < total ? rows.subList(start, end) : List.of();

        Map<String, Object> result = new HashMap<>();
        result.put("total", total);
        result.put("list", list);
        result.put("year", queryYear);
        return Result.success(result);
    }

    @Override
    public Result<?> generateNotices(List<Long> payableIds, Integer noticeType) {
        if (payableIds == null || payableIds.isEmpty()) {
            return Result.error("请选择要生成的记录");
        }
        int type = noticeType == null ? 1 : noticeType;
        Long userId = getCurrentUserId();
        int success = 0;
        for (int i = 0; i < payableIds.size(); i++) {
            PayableAmount pa = payableAmountMapper.selectById(payableIds.get(i));
            if (pa == null) continue;
            if (!isTargetForCollectionNotice(pa, type)) {
                // 已缴清或非目标记录不生成缴款通知书/征收决定书
                continue;
            }
            Company company = companyMapper.selectById(pa.getCompanyId());
            if (company == null) continue;
            if (!canAccessCompany(company)) {
                continue;
            }
            String number = buildNoticeNumber(type, pa.getYear(), pa.getId());
            Notice existed = findMatchedNotice(company.getId(), type, pa.getYear(), number);
            if (existed != null) {
                continue;
            }
            Notice notice = new Notice();
            notice.setCompanyId(pa.getCompanyId());
            notice.setNoticeType(type);
            notice.setNoticeNumber(number);
            notice.setContent(buildNoticeContent(type, company, pa));
            notice.setPrintTime(DateUtil.now());
            notice.setPrintCount(0);
            notice.setSendStatus(0);
            notice.setOperatorId(userId == null ? 1L : userId);
            noticeMapper.insert(notice);
            success++;
        }
        return Result.success("成功生成" + success + "份通知单");
    }

    @Override
    public Result<?> markPrinted(List<Long> noticeIds) {
        if (noticeIds == null || noticeIds.isEmpty()) {
            return Result.error("请选择要打印的通知单");
        }
        String now = DateUtil.now();
        int count = 0;
        for (int i = 0; i < noticeIds.size(); i++) {
            Notice notice = noticeMapper.selectById(noticeIds.get(i));
            if (notice == null) {
                continue;
            }
            Company company = companyMapper.selectById(notice.getCompanyId());
            if (!canAccessCompany(company)) {
                continue;
            }
            noticeMapper.incrementPrintCount(noticeIds.get(i), now);
            noticeMapper.updateSendStatus(noticeIds.get(i), 1);
            count++;
        }
        return Result.success("成功打印" + count + "份通知单");
    }

    @Override
    public void downloadNotice(Long id, HttpServletResponse response) {
        writeNoticePdf(id, response, true);
    }

    @Override
    public void previewNotice(Long id, HttpServletResponse response) {
        writeNoticePdf(id, response, false);
    }

    private void writeNoticePdf(Long id, HttpServletResponse response, boolean asAttachment) {
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
            PdfUtil.generateNoticePdf(notice, company, response, asAttachment);
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

    private Map<String, Object> buildAdminNoticeRow(PayableAmount pa, Integer noticeType) {
        Company company = companyMapper.selectById(pa.getCompanyId());
        if (company == null) {
            return null;
        }
        int type = noticeType == null ? 1 : noticeType;
        String number = buildNoticeNumber(type, pa.getYear(), pa.getId());
        Notice matched = findMatchedNotice(company.getId(), type, pa.getYear(), number);

        Map<String, Object> row = new HashMap<>();
        row.put("id", String.valueOf(pa.getId()));
        row.put("companyName", company.getName());
        row.put("noticeType", getNoticeTypeName(type));
        row.put("year", pa.getYear() + "年");
        row.put("amount", pa.getPayableAmount() == null ? 0D : pa.getPayableAmount());
        row.put("status", matched == null ? "未生成" : (matched.getPrintCount() != null && matched.getPrintCount() > 0 ? "已打印" : "已生成"));
        row.put("generateDate", matched == null ? "" : matched.getPrintTime());
        row.put("noticeId", matched == null ? "" : String.valueOf(matched.getId()));
        row.put("noticeNumber", number);
        return row;
    }

    /**
     * 优先按完整notice_number精确匹配；若应缴记录重算导致payableId变化，
     * 再按 公司+类型+年度 前缀兜底匹配，保证领导端状态与单位端已生成通知一致。
     */
    private Notice findMatchedNotice(Long companyId, Integer noticeType, Integer year, String exactNumber) {
        Notice matched = noticeMapper.selectByNoticeNumber(exactNumber);
        if (matched != null) {
            return matched;
        }
        if (companyId == null || year == null) {
            return null;
        }
        String prefix = (noticeType != null && noticeType == 2 ? "ZSJDS" : "JKTZ") + "-" + year + "-";
        return noticeMapper.selectLatestByCompanyTypeAndYear(companyId, noticeType, prefix);
    }

    private String buildNoticeNumber(Integer type, Integer year, Long payableId) {
        String prefix = type != null && type == 2 ? "ZSJDS" : "JKTZ";
        return prefix + "-" + year + "-" + String.format("%04d", payableId == null ? 0 : payableId);
    }

    private String buildNoticeContent(Integer type, Company company, PayableAmount pa) {
        double amount = pa.getPayableAmount() == null ? 0D : pa.getPayableAmount();
        if (type != null && type == 2) {
            return "【征收决定书】\n单位：" + company.getName() + "\n年度：" + pa.getYear() + "\n应缴金额：¥" + String.format("%.2f", amount) + "\n请按规定期限完成缴纳。";
        }
        return "【缴款通知书】\n单位：" + company.getName() + "\n年度：" + pa.getYear() + "\n应缴金额：¥" + String.format("%.2f", amount) + "\n请于规定时间前完成缴纳。";
    }

    /**
     * 缴款通知书/征收决定书仅面向未缴和部分缴纳单位。
     * paymentStatus: 0-未缴, 1-部分缴, 2-已缴
     */
    private boolean isTargetForCollectionNotice(PayableAmount pa, Integer noticeType) {
        int type = noticeType == null ? 1 : noticeType;
        if (type == 1 || type == 2) {
            Integer paymentStatus = pa.getPaymentStatus();
            return paymentStatus == null || paymentStatus != 2;
        }
        return true;
    }

    private Integer resolveLatestAvailableYear(Long regionIdFilter, Integer noticeType) {
        List<PayableAmount> all = filterByRegionScope(payableAmountMapper.selectAll(), regionIdFilter).stream()
                .filter(pa -> isTargetForCollectionNotice(pa, noticeType))
                .collect(Collectors.toList());
        Integer latest = null;
        for (int i = 0; i < all.size(); i++) {
            Integer year = all.get(i).getYear();
            if (year == null) {
                continue;
            }
            if (latest == null || year > latest) {
                latest = year;
            }
        }
        return latest;
    }

    private Long getCurrentUserId() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }
        HttpServletRequest request = attributes.getRequest();
        Object userIdObj = request.getAttribute("userId");
        if (userIdObj == null) {
            return null;
        }
        return Long.valueOf(userIdObj.toString());
    }

    private List<PayableAmount> filterByRegionScope(List<PayableAmount> source, Long regionIdFilter) {
        Map<String, Object> claims = getClaims();
        if (claims == null) {
            return source;
        }
        Long regionId = resolveEffectiveRegionScope(claims, regionIdFilter);
        if (regionId == null) {
            return source;
        }
        final Long targetRegionId = regionId;
        return source.stream()
                .filter(pa -> {
                    Company company = companyMapper.selectById(pa.getCompanyId());
                    return company != null && targetRegionId.equals(company.getRegionId());
                })
                .collect(Collectors.toList());
    }

    private boolean canAccessCompany(Company company) {
        if (company == null) {
            return false;
        }
        Map<String, Object> claims = getClaims();
        if (claims == null) {
            return true;
        }
        Long regionId = resolveEffectiveRegionScope(claims, null);
        if (regionId == null) {
            // 市级管理员/市级领导可访问全市
            return true;
        }
        return regionId.equals(company.getRegionId());
    }

    private Long resolveEffectiveRegionScope(Map<String, Object> claims, Long regionIdFilter) {
        if (claims == null) {
            return regionIdFilter;
        }
        if (isDistrictScopedUser(claims)) {
            return parseRegionId(claims.get("regionId"));
        }
        // 与市管理员保持一致：非区管理员统一使用页面筛选值
        return regionIdFilter;
    }

    private Long parseRegionId(Object regionIdObj) {
        if (regionIdObj == null) {
            return null;
        }
        try {
            return Long.valueOf(String.valueOf(regionIdObj));
        } catch (Exception e) {
            return null;
        }
    }

    @SuppressWarnings("unchecked")
    private Map<String, Object> getClaims() {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
        if (attributes == null) {
            return null;
        }
        HttpServletRequest request = attributes.getRequest();
        Object userInfo = request.getAttribute("userInfo");
        if (!(userInfo instanceof Map)) {
            return null;
        }
        return (Map<String, Object>) userInfo;
    }

    @SuppressWarnings("unchecked")
    private boolean isDistrictScopedUser(Map<String, Object> claims) {
        if (hasRoleCode(claims, "admin_district")) {
            return true;
        }
        if (isDistrictLeader(claims)) {
            return true;
        }
        if (hasRoleCode(claims, "leader")) {
            // 领导账号中：regionId 有值视为区领导（仅本区）；为空视为市领导（全市）
            return parseRegionId(claims.get("regionId")) != null;
        }
        return false;
    }

    private boolean isDistrictLeader(Map<String, Object> claims) {
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
    private boolean hasRoleCode(Map<String, Object> claims, String roleCode) {
        Object roleCodesObj = claims.get("roleCodes");
        if (!(roleCodesObj instanceof List)) {
            return false;
        }
        List<String> roleCodes = (List<String>) roleCodesObj;
        return roleCodes.contains(roleCode);
    }
}


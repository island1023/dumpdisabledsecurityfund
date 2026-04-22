package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.CompanyService;
import com.example.dumpdisabledsecurityfund.service.EmployeeService;
import com.example.dumpdisabledsecurityfund.service.PaymentService;
import com.example.dumpdisabledsecurityfund.service.NoticeService;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.annotation.Resource;
import org.springframework.web.bind.annotation.*;

@Tag(name = "单位用户模块(PDF规范)", description = "符合PDF文档规范的单位用户相关接口")
@RestController
@RequestMapping("/unit")
public class UnitController {
    @Resource
    private CompanyService companyService;

    @Resource
    private EmployeeService employeeService;

    @Resource
    private PaymentService paymentService;

    @Resource
    private NoticeService noticeService;

    @Resource
    private ReductionService reductionService;

    @Operation(summary = "获取单位基本信息", description = "获取当前登录单位的详细信息")
    @GetMapping("/info")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getInfo() {
        return companyService.getCurrentCompanyInfo();
    }

    @Operation(summary = "获取全体职工列表", description = "获取单位所有职工列表，支持分页")
    @GetMapping("/employees")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getEmployees(
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return employeeService.getAllEmployees(page, pageSize);
    }

    @Operation(summary = "获取残疾职工列表", description = "获取单位残疾职工列表")
    @GetMapping("/disabled-employees")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getDisabledEmployees() {
        return employeeService.getDisabledEmployees();
    }

    @Operation(summary = "获取残疾职工详情", description = "获取指定残疾职工的详细信息（含完整身份证号）")
    @GetMapping("/disabled-employees/{employeeId}")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getDisabledEmployeeDetail(
            @Parameter(description = "残疾职工ID", required = true, example = "1")
            @PathVariable Long employeeId) {
        return employeeService.getDisabledEmployeeDetail(employeeId);
    }

    @Operation(summary = "获取非残疾职工列表", description = "获取非残疾职工列表，用于选择转为残疾职工")
    @GetMapping("/non-disabled-employees")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getNonDisabledEmployees() {
        return employeeService.getNonDisabledEmployees();
    }

    @Operation(summary = "新增普通职工", description = "手动添加或批量导入普通职工")
    @PostMapping("/employees")
    @RequirePermission(roles = {"company_user"})
    public Result<?> addEmployee(@RequestBody Object request) {
        return employeeService.addEmployee(request);
    }

    @Operation(summary = "新增残疾职工", description = "将一个或多个职工设置为残疾职工")
    @PostMapping("/disabled-employees")
    @RequirePermission(roles = {"company_user"})
    public Result<?> addDisabledEmployees(@RequestBody Object request) {
        return employeeService.addDisabledEmployees(request);
    }

    @Operation(summary = "提交残疾职工审核申请", description = "单位提交新增残疾职工申请，等待市/区管理员审核")
    @PostMapping("/disabled-audits")
    @RequirePermission(roles = {"company_user"})
    public Result<?> submitDisabledAuditApplications(@RequestBody Object request) {
        return employeeService.submitDisabledAuditApplications(request);
    }

    @Operation(summary = "获取残疾职工审核申请记录", description = "获取单位新增残疾职工的审核申请列表")
    @GetMapping("/disabled-audits")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getDisabledAuditApplications() {
        return employeeService.getDisabledAuditApplications();
    }

    @Operation(summary = "提交减免缓申请", description = "企业提交减免或缓缴申请")
    @PostMapping("/applications")
    @RequirePermission(roles = {"company_user"})
    public Result<?> submitApplication(@RequestBody Object request) {
        return reductionService.submitApplication(request);
    }

    @Operation(summary = "获取申请历史列表", description = "获取企业的减免缓申请历史记录")
    @GetMapping("/applications")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getApplications(
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return reductionService.getApplications(page, pageSize);
    }

    @Operation(summary = "获取申请详情", description = "获取指定申请的详细信息")
    @GetMapping("/applications/{applicationId}")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getApplicationDetail(
            @Parameter(description = "申请单ID", required = true, example = "1")
            @PathVariable Long applicationId) {
        return reductionService.getApplicationDetail(applicationId);
    }

    @Operation(summary = "获取当前申报进度", description = "获取当前申请的审核进度")
    @GetMapping("/application-progress")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getApplicationProgress() {
        return reductionService.getApplicationProgress();
    }

    @Operation(summary = "获取缴费统计", description = "获取本年度已缴和待缴金额统计")
    @GetMapping("/payment/statistics")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getPaymentStatistics() {
        return paymentService.getPaymentStatistics();
    }

    @Operation(summary = "获取税务平台应缴模拟数据", description = "模拟从外部税务平台拉取本年度应缴金额")
    @GetMapping("/payment/tax-platform")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getTaxPlatformSummary() {
        return paymentService.getMockTaxPlatformSummary();
    }

    @Operation(summary = "获取缴费记录列表", description = "获取企业的缴费历史记录")
    @GetMapping("/payments")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getPayments(
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize) {
        return paymentService.getPayments(page, pageSize);
    }

    @Operation(summary = "获取通知单列表", description = "获取单位的通知单列表")
    @GetMapping("/notices")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getNotices(
            @Parameter(description = "页码，默认1", example = "1")
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @Parameter(description = "每页数量，默认20", example = "20")
            @RequestParam(required = false, defaultValue = "20") Integer pageSize,
            @Parameter(description = "是否只看未读", example = "false")
            @RequestParam(required = false, defaultValue = "false") Boolean unreadOnly) {
        return noticeService.getNotices(page, pageSize, unreadOnly);
    }

    @Operation(summary = "获取通知单详情", description = "获取指定通知单的详细内容")
    @GetMapping("/notices/{noticeId}")
    @RequirePermission(roles = {"company_user"})
    public Result<?> getNoticeDetail(
            @Parameter(description = "通知单ID", required = true, example = "1")
            @PathVariable Long noticeId) {
        return noticeService.getNoticeDetail(noticeId);
    }

    @Operation(summary = "标记通知为已读", description = "将指定通知单标记为已读状态")
    @PutMapping("/notices/{noticeId}/read")
    @RequirePermission(roles = {"company_user"})
    public Result<?> markAsRead(
            @Parameter(description = "通知单ID", required = true, example = "1")
            @PathVariable Long noticeId) {
        return noticeService.markAsRead(noticeId);
    }
}

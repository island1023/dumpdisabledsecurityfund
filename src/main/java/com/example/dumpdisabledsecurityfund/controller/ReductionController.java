package com.example.dumpdisabledsecurityfund.controller;

import com.example.dumpdisabledsecurityfund.common.RequirePermission;
import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.dto.ReductionApplyDTO;
import com.example.dumpdisabledsecurityfund.service.ReductionService;
import jakarta.annotation.Resource;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/reduction")
public class ReductionController {

    @Resource
    private ReductionService reductionService;

    @PostMapping("/apply")
    @RequirePermission(roles = {"company_user"})
    public Result<?> apply(@Valid @RequestBody ReductionApplyDTO dto) {
        return reductionService.apply(dto);
    }

    @GetMapping("/list")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> getList(@RequestParam(required = false) Long companyId,
                             @RequestParam(required = false) Integer year,
                             @RequestParam(required = false) Integer auditStatus) {
        return reductionService.getList(companyId, year, auditStatus);
    }

    @GetMapping("/{id}")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district", "company_user"})
    public Result<?> getDetail(@PathVariable Long id) {
        return reductionService.getDetail(id);
    }

    @PostMapping("/audit")
    @RequirePermission(roles = {"admin_system", "admin_city", "admin_district"})
    public Result<?> audit(@RequestParam Long id,
                           @RequestParam Integer auditStatus,
                           @RequestParam(required = false) String auditOpinion) {
        return reductionService.audit(id, auditStatus, auditOpinion);
    }

    @DeleteMapping("/withdraw/{id}")
    @RequirePermission(roles = {"company_user"})
    public Result<?> withdraw(@PathVariable Long id) {
        return reductionService.withdraw(id);
    }
}

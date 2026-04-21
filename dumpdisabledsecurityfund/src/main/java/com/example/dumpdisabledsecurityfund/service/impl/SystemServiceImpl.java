package com.example.dumpdisabledsecurityfund.service.impl;

import com.example.dumpdisabledsecurityfund.common.Result;
import com.example.dumpdisabledsecurityfund.service.SystemService;
import org.springframework.stereotype.Service;
import java.util.HashMap;
import java.util.Map;

@Service
public class SystemServiceImpl implements SystemService {
    @Override
    public Result<?> getSystemInfo() {
        Map<String, String> map = new HashMap<>();
        map.put("name", "娈嬬柧浜哄氨涓氫繚闅滈噾绠＄悊绯荤粺");
        map.put("version", "1.0.0");
        return Result.success(map);
    }
}
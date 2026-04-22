import { get, post } from './HttpUtil';

/**
 * 单位基本信息
 */
export interface CompanyInfo {
  id: string;
  name: string;
  creditCode: string;
  industry: string;
  establishDate: string;
  address: string;
  legalPerson: string;
  contactPhone: string;
  totalEmployees: number;
  totalEmployeeRecords?: number;
  disabledEmployees: number;
  status: string;
}

/**
 * 职工信息
 */
export interface Employee {
  id: string;
  name: string;
  idCard: string;
  hireDate?: string;
  disabilityLevel?: string;
  certificate?: string;
}

/**
 * 残疾职工详情
 */
export interface DisabledEmployeeDetail {
  name: string;
  idCard: string;
  disabilityType: string;
  disabilityLevel: string;
  hireDate: string;
  approvedDate: string;
}

export interface DisabledAuditApplication {
  id: string;
  name: string;
  idCard: string;
  status: string;
  date?: string;
}

class DisabledAuditApplicationData implements DisabledAuditApplication {
  id: string = '';
  name: string = '';
  idCard: string = '';
  status: string = '审批中';
  date?: string = '';
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  total: number;
  list: T[];
}

export class AddEmployeeData {
  name?: string;
  idCard?: string;
  hireDate?: string;
  jobPosition?: string;
}

class AddEmployeeRequestEmployee {
  name: string = '';
  idCard: string = '';
  hireDate: string = '';
  jobPosition: string = '';
}

class AddEmployeeRequest {
  mode: string = 'manual';
  employee: AddEmployeeRequestEmployee = new AddEmployeeRequestEmployee();
}

export class AddDisabledEmployeeData {
  employeeIds?: string[];
  disabilityType?: string;
  disabilityLevel?: string;
  attachment?: string;
}

export interface AddEmployeeResponse {
  id: string;
}

class AddEmployeeResponseData implements AddEmployeeResponse {
  id: string = '';
}

class CompanyInfoData {
  id: string = '';
  name: string = '';
  creditCode: string = '';
  industry: string = '';
  establishDate: string = '';
  address: string = '';
  legalPerson: string = '';
  contactPhone: string = '';
  totalEmployees: number = 0;
  totalEmployeeRecords: number = 0;
  disabledEmployees: number = 0;
  status: string = 'INACTIVE';
}

function pickFirstDefined(raw: Record<string, Object>, keys: string[]): Object | undefined {
  for (let i = 0; i < keys.length; i++) {
    const value = raw[keys[i]];
    if (value !== undefined && value !== null && String(value).length > 0) {
      return value;
    }
  }
  return undefined;
}

function asRecord(value: Object | undefined): Record<string, Object> {
  if (value && typeof value === 'object') {
    return value as Record<string, Object>;
  }
  return {};
}

function normalizePageResponse(rawData: Object): PageResponse<Employee> {
  const root = asRecord(rawData);
  const nested = asRecord(root['data']);
  const source = Object.keys(nested).length > 0 ? nested : root;
  const totalValue = pickFirstDefined(source, ['total', 'count', 'totalCount', 'total_count']);
  const listValue = pickFirstDefined(source, ['list', 'records', 'rows']);
  return {
    total: Number(totalValue ?? 0),
    list: (listValue as Employee[]) || []
  };
}

function normalizeEmployeeList(rawData: Object): Employee[] {
  if (rawData instanceof Array) {
    return rawData as Employee[];
  }
  const root = asRecord(rawData);
  const nested = asRecord(root['data']);
  const source = Object.keys(nested).length > 0 ? nested : root;
  const listValue = pickFirstDefined(source, ['list', 'records', 'rows']);
  if (listValue) {
    return listValue as Employee[];
  }
  return [];
}

function normalizeObjectList(rawData: Object): Record<string, Object>[] {
  if (rawData instanceof Array) {
    return rawData as Record<string, Object>[];
  }
  const root = asRecord(rawData);
  const nested = asRecord(root['data']);
  const source = Object.keys(nested).length > 0 ? nested : root;
  const listValue = pickFirstDefined(source, ['list', 'records', 'rows']);
  if (listValue) {
    return listValue as Record<string, Object>[];
  }
  return [];
}

/**
 * 单位服务
 */
export class UnitService {
  /**
   * 获取单位基本信息
   */
  static async getCompanyInfo(): Promise<CompanyInfo> {
    const response = await get<Record<string, Object>>('/unit/info');
    
    if (response.code === 200) {
      // 兼容后端返回结构差异：data 可能再次嵌套在 data 字段中
      const responseData = response.data as Record<string, Object>;
      const nestedData = responseData && responseData['data'] as Record<string, Object> | undefined;
      const raw = nestedData && typeof nestedData === 'object' ? nestedData : responseData;
      const info = new CompanyInfoData();

      const idValue = pickFirstDefined(raw, ['id']);
      const nameValue = pickFirstDefined(raw, ['name', 'companyName']);
      const creditCodeValue = pickFirstDefined(raw, ['creditCode', 'unifiedSocialCreditCode', 'unified_social_credit_code']);
      const industryValue = pickFirstDefined(raw, ['industry']);
      const establishDateValue = pickFirstDefined(raw, ['establishDate', 'establish_date']);
      const addressValue = pickFirstDefined(raw, ['address', 'registerAddress', 'register_address']);
      const legalPersonValue = pickFirstDefined(raw, ['legalPerson', 'legal_person']);
      const contactPhoneValue = pickFirstDefined(raw, ['contactPhone', 'contact_phone', 'mobile', 'phone']);
      const totalEmployeesValue = pickFirstDefined(raw, ['totalEmployees', 'employeeCount', 'employee_count']);
      const totalEmployeeRecordsValue = pickFirstDefined(raw, ['totalEmployeeRecords', 'totalEmployeeRecordsCount', 'employeeTotal', 'employee_total']);
      const disabledEmployeesValue = pickFirstDefined(raw, ['disabledEmployees', 'disabledCount', 'disabled_count']);
      const statusNameValue = pickFirstDefined(raw, ['statusName', 'status_name']);
      const statusValue = pickFirstDefined(raw, ['status']);

      info.id = String(idValue ?? '');
      info.name = String(nameValue ?? '');
      info.creditCode = String(creditCodeValue ?? '');
      info.industry = String(industryValue ?? '');
      info.establishDate = String(establishDateValue ?? '');
      info.address = String(addressValue ?? '');
      info.legalPerson = String(legalPersonValue ?? '');
      info.contactPhone = String(contactPhoneValue ?? '');
      info.totalEmployees = Number(totalEmployeesValue ?? 0);
      info.totalEmployeeRecords = Number(totalEmployeeRecordsValue ?? 0);
      info.disabledEmployees = Number(disabledEmployeesValue ?? 0);

      const nameStr = String(statusNameValue ?? '').trim();
      if (nameStr.indexOf('正常') >= 0) {
        info.status = 'ACTIVE';
      } else if (nameStr.indexOf('异常') >= 0) {
        info.status = 'INACTIVE';
      } else {
        const rawStatus = String(statusValue ?? '').trim().toUpperCase();
        if (rawStatus === '1' || rawStatus === 'ACTIVE' || rawStatus === '正常'.toUpperCase()) {
          info.status = 'ACTIVE';
        } else {
          info.status = 'INACTIVE';
        }
      }
      return info;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取全体职工列表
   */
  static async getEmployees(page: number = 1, pageSize: number = 20): Promise<PageResponse<Employee>> {
    const params: Record<string, string | number | boolean> = {};
    if (page) {
      params.page = page;
    }
    if (pageSize) {
      params.pageSize = pageSize;
    }
    const response = await get<Object>('/unit/employees', params);
    
    if (response.code === 200) {
      return normalizePageResponse(response.data);
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取残疾职工列表
   */
  static async getDisabledEmployees(): Promise<Employee[]> {
    const response = await get<Object>('/unit/disabled-employees');
    
    if (response.code === 200) {
      return normalizeEmployeeList(response.data);
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取残疾职工详情
   */
  static async getDisabledEmployeeDetail(employeeId: string): Promise<DisabledEmployeeDetail> {
    const response = await get<Record<string, Object>>(`/unit/disabled-employees/${employeeId}`);
    
    if (response.code === 200) {
      const responseData = response.data as Record<string, Object>;
      const nestedData = responseData && responseData['data'] as Record<string, Object> | undefined;
      const raw = nestedData && typeof nestedData === 'object' ? nestedData : responseData;
      return {
        name: String(pickFirstDefined(raw, ['name', 'employeeName', 'realName']) ?? ''),
        idCard: String(pickFirstDefined(raw, ['idCard', 'id_card']) ?? ''),
        disabilityType: String(pickFirstDefined(raw, ['disabilityType', 'type', 'disability_type']) ?? ''),
        disabilityLevel: String(pickFirstDefined(raw, ['disabilityLevel', 'level', 'disability_level']) ?? ''),
        hireDate: String(pickFirstDefined(raw, ['hireDate', 'entryDate', 'entry_time', 'entryTime']) ?? ''),
        approvedDate: String(pickFirstDefined(raw, ['approvedDate', 'approveDate', 'approvalDate', 'auditPassTime', 'audit_pass_time']) ?? '')
      };
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取非残疾职工列表
   */
  static async getNonDisabledEmployees(): Promise<Employee[]> {
    const response = await get<Object>('/unit/non-disabled-employees');
    
    if (response.code === 200) {
      return normalizeEmployeeList(response.data);
    }
    
    throw new Error(response.message);
  }

  /**
   * 新增普通职工
   */
  static async addEmployee(data: AddEmployeeData): Promise<AddEmployeeResponse> {
    // 后端接口期望结构：{ mode: "manual", employee: { name, idCard, hireDate, jobPosition } }
    const payload = new AddEmployeeRequest();
    payload.mode = 'manual';
    payload.employee.name = data.name || '';
    payload.employee.idCard = data.idCard || '';
    payload.employee.hireDate = data.hireDate || '';
    payload.employee.jobPosition = data.jobPosition || '';

    const response = await post<Record<string, Object>>('/unit/employees', payload as Object);
    
    if (response.code === 200) {
      const raw = response.data as Record<string, Object>;
      const nested = raw && raw['data'] as Record<string, Object> | undefined;
      const source = nested && typeof nested === 'object' ? nested : raw;
      const idVal = pickFirstDefined(source, ['id']);
      const result = new AddEmployeeResponseData();
      result.id = String(idVal ?? '');
      return result;
    }
    
    throw new Error(response.message);
  }

  /**
   * 新增残疾职工
   */
  static async addDisabledEmployees(data: AddDisabledEmployeeData): Promise<boolean> {
    const response = await post('/unit/disabled-employees', data);
    return response.code === 200;
  }

  static async submitDisabledAuditApplications(data: AddDisabledEmployeeData): Promise<boolean> {
    const response = await post('/unit/disabled-audits', data as Object);
    return response.code === 200;
  }

  static async getDisabledAuditApplications(): Promise<DisabledAuditApplication[]> {
    const response = await get<Object>('/unit/disabled-audits');
    if (response.code === 200) {
      const list = normalizeObjectList(response.data);
      const mapped: DisabledAuditApplication[] = [];
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const data = new DisabledAuditApplicationData();
        data.id = String(item['id'] ?? '');
        data.name = String(item['name'] ?? '');
        data.idCard = String(item['idCard'] ?? '');
        data.status = String(item['status'] ?? '审批中');
        data.date = String(item['date'] ?? '');
        mapped.push(data);
      }
      return mapped;
    }
    throw new Error(response.message);
  }
}

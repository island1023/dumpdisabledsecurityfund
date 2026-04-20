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

/**
 * 单位服务
 */
export class UnitService {
  /**
   * 获取单位基本信息
   */
  static async getCompanyInfo(): Promise<CompanyInfo> {
    const response = await get<CompanyInfo>('/unit/info');
    
    if (response.code === 200) {
      return response.data;
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
    const response = await get<PageResponse<Employee>>('/unit/employees', params);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取残疾职工列表
   */
  static async getDisabledEmployees(): Promise<Employee[]> {
    const response = await get<Employee[]>('/unit/disabled-employees');
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取残疾职工详情
   */
  static async getDisabledEmployeeDetail(employeeId: string): Promise<DisabledEmployeeDetail> {
    const response = await get<DisabledEmployeeDetail>(`/unit/disabled-employees/${employeeId}`);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取非残疾职工列表
   */
  static async getNonDisabledEmployees(): Promise<Employee[]> {
    const response = await get<Employee[]>('/unit/non-disabled-employees');
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 新增普通职工
   */
  static async addEmployee(data: AddEmployeeData): Promise<AddEmployeeResponse> {
    const response = await post<AddEmployeeResponse>('/unit/employees', data);
    
    if (response.code === 200) {
      return response.data;
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
}

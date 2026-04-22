import { get } from './HttpUtil';

/** 领导端单位档案列表行 */
export interface LeaderArchiveListItem {
  id: string;
  companyName: string;
  creditCode: string;
  legalPerson: string;
  registerAddress: string;
  establishDate: string;
  phone: string;
  employeeCount: number;
  disabledCount: number;
  collectionYear: string;
  district: string;
}

/** 历年应缴实缴 */
export interface LeaderPaymentArchiveRow {
  year: string;
  payableAmount: number;
  paidAmount: number;
  status: string;
  payDate?: string;
}

/** 减免缓 */
export interface LeaderReliefArchiveRow {
  type: string;
  reason: string;
  startDate: string;
  endDate: string;
  amount: number;
  status: string;
}

export interface LeaderArchiveDetail {
  id: string;
  companyName: string;
  creditCode: string;
  legalPerson: string;
  registerAddress: string;
  establishDate: string;
  phone: string;
  industry: string;
  employeeCount: number;
  disabledCount: number;
  collectionYear: string;
  district: string;
  paymentRecords: LeaderPaymentArchiveRow[];
  reliefStatuses: LeaderReliefArchiveRow[];
}

export interface LeaderFundUsageItem {
  id: string;
  projectName: string;
  projectType: string;
  district: string;
  amount: number;
  usageDate: string;
  status: string;
  description: string;
  beneficiaryCount: number;
}

export interface LeaderReportBundle {
  year: number;
  month: number;
  reportType: string;
  rows: Record<string, Object>[];
}

export class LeaderService {
  private static asRecord(value: Object | undefined): Record<string, Object> {
    if (value && typeof value === 'object') {
      return value as Record<string, Object>;
    }
    return {};
  }

  private static readString(source: Record<string, Object>, keys: string[], fallback: string = ''): string {
    for (let i = 0; i < keys.length; i++) {
      const value = source[keys[i]];
      if (typeof value === 'string' && value.trim().length > 0) {
        return value;
      }
      if (typeof value === 'number') {
        return `${value}`;
      }
    }
    return fallback;
  }

  private static readNumber(source: Record<string, Object>, keys: string[], fallback: number = 0): number {
    for (let i = 0; i < keys.length; i++) {
      const value = source[keys[i]];
      if (typeof value === 'number') {
        return value;
      }
      if (typeof value === 'string' && value.trim().length > 0) {
        const num = Number(value);
        if (!Number.isNaN(num)) {
          return num;
        }
      }
    }
    return fallback;
  }

  static async getArchiveCompanies(keyword: string, pageNum: number = 1, pageSize: number = 50): Promise<LeaderArchiveListItem[]> {
    const queryParams: Record<string, string | number> = {};
    queryParams.pageNum = pageNum;
    queryParams.pageSize = pageSize;
    if (keyword && keyword.trim().length > 0) {
      queryParams.keyword = keyword.trim();
    }
    const response = await get<Object>('/leader/archive/companies', queryParams);
    if (response.code !== 200) {
      throw new Error(response.message || '加载单位档案失败');
    }
    const root = LeaderService.asRecord(response.data as Object);
    const listValue = root['list'] as Object[] | undefined;
    const out: LeaderArchiveListItem[] = [];
    if (listValue && Array.isArray(listValue)) {
      for (let i = 0; i < listValue.length; i++) {
        const row = LeaderService.asRecord(listValue[i]);
        out.push({
          id: LeaderService.readString(row, ['id']),
          companyName: LeaderService.readString(row, ['companyName']),
          creditCode: LeaderService.readString(row, ['creditCode']),
          legalPerson: LeaderService.readString(row, ['legalPerson']),
          registerAddress: LeaderService.readString(row, ['registerAddress']),
          establishDate: LeaderService.readString(row, ['establishDate']),
          phone: LeaderService.readString(row, ['phone']),
          employeeCount: LeaderService.readNumber(row, ['employeeCount']),
          disabledCount: LeaderService.readNumber(row, ['disabledCount']),
          collectionYear: LeaderService.readString(row, ['collectionYear'], '—'),
          district: LeaderService.readString(row, ['district'], '—')
        });
      }
    }
    return out;
  }

  static async getArchiveDetail(companyId: string): Promise<LeaderArchiveDetail> {
    const response = await get<Object>(`/leader/archive/companies/${companyId}`);
    if (response.code !== 200) {
      throw new Error(response.message || '加载档案详情失败');
    }
    const row = LeaderService.asRecord(response.data as Object);

    const payList: LeaderPaymentArchiveRow[] = [];
    const payRaw = row['paymentRecords'] as Object[] | undefined;
    if (payRaw && Array.isArray(payRaw)) {
      for (let i = 0; i < payRaw.length; i++) {
        const p = LeaderService.asRecord(payRaw[i]);
        payList.push({
          year: LeaderService.readString(p, ['year']),
          payableAmount: LeaderService.readNumber(p, ['payableAmount']),
          paidAmount: LeaderService.readNumber(p, ['paidAmount']),
          status: LeaderService.readString(p, ['status']),
          payDate: LeaderService.readString(p, ['payDate'])
        });
      }
    }

    const reliefList: LeaderReliefArchiveRow[] = [];
    const relRaw = row['reliefStatuses'] as Object[] | undefined;
    if (relRaw && Array.isArray(relRaw)) {
      for (let i = 0; i < relRaw.length; i++) {
        const r = LeaderService.asRecord(relRaw[i]);
        reliefList.push({
          type: LeaderService.readString(r, ['type']),
          reason: LeaderService.readString(r, ['reason']),
          startDate: LeaderService.readString(r, ['startDate']),
          endDate: LeaderService.readString(r, ['endDate']),
          amount: LeaderService.readNumber(r, ['amount']),
          status: LeaderService.readString(r, ['status'])
        });
      }
    }

    return {
      id: LeaderService.readString(row, ['id']),
      companyName: LeaderService.readString(row, ['companyName']),
      creditCode: LeaderService.readString(row, ['creditCode']),
      legalPerson: LeaderService.readString(row, ['legalPerson']),
      registerAddress: LeaderService.readString(row, ['registerAddress']),
      establishDate: LeaderService.readString(row, ['establishDate']),
      phone: LeaderService.readString(row, ['phone']),
      industry: LeaderService.readString(row, ['industry']),
      employeeCount: LeaderService.readNumber(row, ['employeeCount']),
      disabledCount: LeaderService.readNumber(row, ['disabledCount']),
      collectionYear: LeaderService.readString(row, ['collectionYear']),
      district: LeaderService.readString(row, ['district']),
      paymentRecords: payList,
      reliefStatuses: reliefList
    };
  }

  static async getFundUsage(keyword: string, projectType: string): Promise<LeaderFundUsageItem[]> {
    const queryParams: Record<string, string> = {};
    if (keyword && keyword.trim().length > 0) {
      queryParams.keyword = keyword.trim();
    }
    if (projectType && projectType.length > 0 && projectType !== 'all') {
      queryParams.projectType = projectType;
    }
    const response = await get<Object>('/leader/fund-usage', queryParams);
    if (response.code !== 200) {
      throw new Error(response.message || '加载残保金使用数据失败');
    }
    const arr = response.data as Object[] | undefined;
    const out: LeaderFundUsageItem[] = [];
    if (arr && Array.isArray(arr)) {
      for (let i = 0; i < arr.length; i++) {
        const r = LeaderService.asRecord(arr[i]);
        out.push({
          id: LeaderService.readString(r, ['id']),
          projectName: LeaderService.readString(r, ['projectName']),
          projectType: LeaderService.readString(r, ['projectType']),
          district: LeaderService.readString(r, ['district']),
          amount: LeaderService.readNumber(r, ['amount']),
          usageDate: LeaderService.readString(r, ['usageDate']),
          status: LeaderService.readString(r, ['status']),
          description: LeaderService.readString(r, ['description']),
          beneficiaryCount: LeaderService.readNumber(r, ['beneficiaryCount'])
        });
      }
    }
    return out;
  }

  static async getReport(typeCode: string, year: number, month: number): Promise<LeaderReportBundle> {
    const reportParams: Record<string, string | number> = {};
    reportParams.type = typeCode;
    reportParams.year = year;
    reportParams.month = month;
    const response = await get<Object>('/leader/reports', reportParams);
    if (response.code !== 200) {
      throw new Error(response.message || '加载统计报表失败');
    }
    const root = LeaderService.asRecord(response.data as Object);
    const rowsRaw = root['rows'] as Object[] | undefined;
    const rows: Record<string, Object>[] = [];
    if (rowsRaw && Array.isArray(rowsRaw)) {
      for (let i = 0; i < rowsRaw.length; i++) {
        rows.push(LeaderService.asRecord(rowsRaw[i]));
      }
    }
    return {
      year: LeaderService.readNumber(root, ['year'], year),
      month: LeaderService.readNumber(root, ['month'], month),
      reportType: LeaderService.readString(root, ['reportType'], typeCode),
      rows
    };
  }
}

import { get } from './HttpUtil';

export interface LeaderStatisticsData {
  year: number;
  totalCompany: number;
  totalPayableFund: number;
  paidCompany: number;
  unpaidCompany: number;
  reductionApplyAmount: number;
  fundUsageAmount: number;
}

export class LeaderReportService {
  static async getStatistics(year?: number): Promise<LeaderStatisticsData> {
    const params: Record<string, string | number | boolean> = {};
    if (year) {
      params.year = year;
    }
    const response = await get<LeaderStatisticsData>('/report/statistics', params);
    if (response.code === 200) {
      return response.data;
    }
    throw new Error(response.message || '获取统计数据失败');
  }
}

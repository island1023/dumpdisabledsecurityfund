
import { get, post, del } from './HttpUtil';

/**
 * 减免申请信息
 */
export interface Application {
  id: string;
  type: string;
  year: string;
  amount: string;
  reason?: string;
  attachment?: string;
  status: string;
  date?: string;
  submitDate?: string;
}

/**
 * 申报进度步骤
 */
export interface ProgressStep {
  title: string;
  status: 'completed' | 'current' | 'pending';
  time: string;
}

/**
 * 申报进度
 */
export interface ApplicationProgress {
  currentStep: string;
  steps: ProgressStep[];
  message: string;
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  total: number;
  list: T[];
}

/**
 * 减免申请提交数据
 */
export interface ApplicationSubmitData {
  type: string;
  year: string;
  amount: string;
  reason: string;
  attachment: string;
}

/**
 * 减免申请响应
 */
export interface ApplicationSubmitResponse {
  applicationId: string;
}

class ApplicationSubmitRequestData {
  type?: string;
  year?: string;
  amount?: string;
  reason?: string;
  attachment?: string;
}

/**
 * 减免申请服务
 */
export class ReductionService {
  /**
   * 提交减免缓申请
   */
  static async submitApplication(data: ApplicationSubmitData): Promise<ApplicationSubmitResponse> {
    const requestData = new ApplicationSubmitRequestData();
    if (data.type) {
      requestData.type = data.type;
    }
    if (data.year) {
      requestData.year = data.year;
    }
    if (data.amount) {
      requestData.amount = data.amount;
    }
    if (data.reason) {
      requestData.reason = data.reason;
    }
    if (data.attachment) {
      requestData.attachment = data.attachment;
    }
    const response = await post<ApplicationSubmitResponse>('/unit/applications', requestData);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取申请历史列表
   */
  static async getApplications(page: number = 1, pageSize: number = 20): Promise<PageResponse<Application>> {
    const params: Record<string, string | number | boolean> = {};
    if (page) {
      params.page = page;
    }
    if (pageSize) {
      params.pageSize = pageSize;
    }
    const response = await get<PageResponse<Application>>('/unit/applications', params);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取申请详情
   */
  static async getApplicationDetail(applicationId: string): Promise<Application> {
    const response = await get<Application>(`/unit/applications/${applicationId}`);
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 获取当前申报进度
   */
  static async getApplicationProgress(): Promise<ApplicationProgress> {
    const response = await get<ApplicationProgress>('/unit/application-progress');
    
    if (response.code === 200) {
      return response.data;
    }
    
    throw new Error(response.message);
  }

  /**
   * 撤销减免缓申请
   * @param applicationId 申请ID
   */
  static async cancelApplication(applicationId: string): Promise<void> {
    console.log('>>> 开始撤销申请:', applicationId);

    const response = await del<void>(`/reduction/withdraw/${applicationId}`);

    if (response.code === 200) {
      console.log('>>> 撤销申请成功');
      return;
    }

    throw new Error(response.message || '撤销申请失败');
  }
}

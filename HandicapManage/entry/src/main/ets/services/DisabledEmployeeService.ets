import { uploadFile, get, del } from './HttpUtil';

/**
 * 1. 显式定义导入结果接口
 * 确保这个定义在类使用它之前，或者在该文件中是可见的
 */
export interface ImportResult {
  successCount: number;
  failCount: number;
  // 如果后端有返回具体的错误信息列表，可以加上：
  // errorMessages?: Array<string>;
}

/**
 * 残疾人证附件信息
 */
export interface DisabilityCertificate {
  id: string;
  fileName: string;
  fileUrl: string;
  fileSize: string;
  uploadTime: string;
}

/**
 * 残疾人证上传结果
 */
export interface CertificateUploadResult {
  id: string;
  url: string;
  fileName: string;
  fileSize: string;
}

/**
 * 辅助函数：处理文件路径
 * 放在类外部以避免 'this' 指向问题
 */
function getCleanPath(fileUri: string): string {
  let cleanPath: string = fileUri;
  if (cleanPath.indexOf('://') !== -1) {
    cleanPath = cleanPath.substring(cleanPath.indexOf('://') + 3);
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/' + cleanPath;
    }
  }
  return cleanPath;
}

/**
 * 残疾职工管理服务
 */
export class DisabledEmployeeService {

  /**
   * 批量导入残疾职工
   */
  static async importDisabledEmployees(fileUri: string, fileName: string): Promise<ImportResult> {
    const cleanPath = getCleanPath(fileUri);
    try {
      // 这里的 <ImportResult> 现在可以被识别了
      const response = await uploadFile<ImportResult>('/employee/importDisabled', cleanPath, 'file', fileName);

      if (response.code === 200) {
        return response.data;
      } else {
        throw new Error(response.message || '导入失败');
      }
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 批量导入普通职工
   */
  static async importNormalEmployees(fileUri: string, fileName: string): Promise<ImportResult> {
    const cleanPath = getCleanPath(fileUri);
    try {
      const response = await uploadFile<ImportResult>('/employee/importNormal', cleanPath, 'file', fileName);

      if (response.code === 200) {
        return response.data;
      } else {
        throw new Error(response.message || '导入失败');
      }
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 上传残疾人证
   */
  /**
   * 上传残疾人证
   */
  static async uploadDisabilityCertificate(
    fileUri: string,
    fileName: string,
    employeeId: string
  ): Promise<CertificateUploadResult> {
    try {
      const url = `/employee/uploadDisabilityCertificate?employeeId=${employeeId}`;
      const response = await uploadFile<CertificateUploadResult>(url, fileUri, 'file', fileName);

      if (response.code === 200) {
        return response.data;
      } else {
        throw new Error(response.message || '上传失败');
      }
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }


  /**
   * 获取职工残疾人证
   */
  static async getDisabilityCertificate(employeeId: string): Promise<DisabilityCertificate | null> {
    try {
      const response = await get<DisabilityCertificate | null>(`/employee/disabilityCertificate/${employeeId}`);
      if (response.code === 200) {
        return response.data;
      } else {
        throw new Error(response.message || '获取失败');
      }
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }

  /**
   * 删除残疾人证
   */
  static async deleteDisabilityCertificate(attachmentId: string): Promise<void> {
    try {
      const response = await del<null>(`/employee/disabilityCertificate/${attachmentId}`);
      if (response.code !== 200) {
        throw new Error(response.message || '删除失败');
      }
    } catch (error) {
      const err: Error = error instanceof Error ? error : new Error(String(error));
      throw err;
    }
  }
}
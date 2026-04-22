import { ColorConstants } from '../../common/constants/ColorConstants';
import { appViewModel } from '../../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
import { UnitService, AddEmployeeData, AddDisabledEmployeeData, AddEmployeeResponse, DisabledAuditApplication, ImportResult,ImportStatistics } from '../../services/UnitService';
import { PaymentService, NoticeService } from '../../services/PaymentAndNoticeService';
import { ReductionService, ApplicationSubmitData } from '../../services/ReductionService';
import { AuthService } from '../../services/AuthService';
import { DisabledEmployeeService, DisabilityCertificate } from '../../services/DisabledEmployeeService';
import { promptAction } from '@kit.ArkUI';
import { picker } from '@kit.CoreFileKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Context } from '@kit.AbilityKit';

enum CustomSheetType {
  NONE,
  PROFILE,
  EDIT_PROFILE,
  ALL_EMPLOYEES,
  EMPLOYEE_DETAIL,
  APP_FORM,
  APP_DETAIL,
  NOTICE_DETAIL,
  ADD_EMPLOYEE,
  ADD_DISABLED
}

interface TabItem { id: string; name: string; icon: string; }
interface EmployeeInfo { id: string; name: string; idCard: string; disabilityLevel: string; certificate: string; status?: string; }
interface AllEmployee { id: string; name: string; idCard: string; hireDate?: string; }
interface DisabledEmployeeDetail { id: string; name: string; idCard: string; disabilityType: string; disabilityLevel: string; hireDate: string; approvedDate: string; }
interface ApplicationRecord { id: string; type: string; year: string; amount: string; status: string; date: string; }
interface ApplicationDetail { id: string; type: string; year: string; amount: string; reason: string; attachment: string; status: string; submitDate: string; }
interface PaymentRecord { period: string; amount: string; date: string; status: string; }
interface NoticeItem { id: string; title: string; date: string; type: string; read: boolean; }
interface NoticeDetail { id: string; title: string; date: string; type: string; content: string; }
interface NonDisabledEmployee { id: string; name: string; idCard: string; }

interface PaymentStats {
  paidAmount: number;
  pendingAmount: number;
}

interface CompanyInfo {
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



@Entry
@Component
export struct UnitHomePage {
  /** 由 MainPage 传入：页面每次显示时递增，用于补一次数据拉取，避免首帧 0 人/状态未刷新 */
  @Watch('onUnitRefreshNonce') @Prop refreshNonce: number = 0;
  // 单位用户登录后默认进入"残疾职工"页，避免首屏先看到单位信息中尚未刷新完成的统计值
  @State currentTab: string = 'disabled';
  @State isSheetShow: boolean = false;
  @State activeSheet: CustomSheetType = CustomSheetType.NONE;
  @State editUsername: string = '';
  @State editOldPassword: string = '';
  @State editPassword: string = '';
  @State editConfirmPassword: string = '';
  @State editSaving: boolean = false;
  @State editError: string = '';
  @State selectedApplication: ApplicationDetail | null = null;
  @State selectedNotice: NoticeDetail | null = null;
  @State appFormType: string = '减';
  @State appFormYear: string = '2025';
  @State appFormAmount: string = '';
  @State appFormReason: string = '';
  @State appFormAttachment: string = '';
  @State showAddEmployeeDialog: boolean = false;
  @State addEmployeeMode: string = '手动添加';
  @State newEmployeeName: string = '';
  @State newEmployeeIdCard: string = '';
  @State newEmployeeHireDate: string = '';
  @State showAddDisabledDialog: boolean = false;
  @State selectedNonDisabledEmployees: string[] = [];
  @State newDisabilityType: string = '肢体残疾';
  @State newDisabilityLevel: string = '';
  @State newDisabilityAttachment: string = '';
  @State showImportDialog: boolean = false;

  // 数据状态
  @State companyInfo: CompanyInfo | null = null;
  @State disabledEmployees: EmployeeInfo[] = [];
  @State allEmployees: AllEmployee[] = [];
  @State nonDisabledEmployees: NonDisabledEmployee[] = [];
  @State applications: ApplicationRecord[] = [];
  @State paymentStats: PaymentStats = { paidAmount: 0, pendingAmount: 0 };
  @State paymentRecords: PaymentRecord[] = [];
  @State notices: NoticeItem[] = [];
  @State isLoading: boolean = false;
  @State companyNameText: string = '';
  @State companyCreditCodeText: string = '';
  @State companyIndustryText: string = '';
  @State companyEstablishDateText: string = '';
  @State companyAddressText: string = '';
  @State companyLegalPersonText: string = '';
  @State companyContactPhoneText: string = '';
  @State companyStatusText: string = 'INACTIVE';
  @State totalEmployeesCount: number = 0;
  @State disabledEmployeesCount: number = 0;

  @State selectedEmployee: DisabledEmployeeDetail | null = null;
  @State disabilityCertificate: DisabilityCertificate | null = null;
  @State showUploadCertDialog: boolean = false;

  private tabs: TabItem[] = [
    { id: 'info', name: '单位信息', icon: 'building_fill' },
    { id: 'disabled', name: '残疾职工', icon: 'person_2_fill' },
    { id: 'application', name: '减免缓申请', icon: 'doc_text_fill' },
    { id: 'payment', name: '缴费记录', icon: 'creditcard_fill' },
    { id: 'notice', name: '通知单', icon: 'bell_fill' }
  ] as TabItem[];

  private unitBootstrapRunning: boolean = false;

  aboutToAppear() {
    setTimeout(() => {
      void this.bootstrapUnitHome();
    }, 0);
  }

  private onUnitRefreshNonce(): void {
    if (this.refreshNonce > 0) {
      void this.bootstrapUnitHome();
    }
  }

  private async bootstrapUnitHome(): Promise<void> {
    if (this.unitBootstrapRunning) {
      return;
    }
    this.unitBootstrapRunning = true;
    try {
      await this.loadCompanyInfo();
      await Promise.all([
        this.loadDisabledEmployees(),
        this.loadApplications(),
        this.loadPaymentInfo(),
        this.loadNotices()
      ]);
    } finally {
      this.unitBootstrapRunning = false;
    }
  }

  private async openAllEmployeesSheet(): Promise<void> {
    await this.loadAllEmployees();
    this.openSheet(CustomSheetType.ALL_EMPLOYEES);
  }

  async loadCompanyInfo() {
    try {
      const info = await UnitService.getCompanyInfo();
      const previous = this.companyInfo;
      const safeText = (next: string, oldVal: string): string => {
        return next && next.trim().length > 0 ? next : oldVal;
      };
      const companyData: CompanyInfo = {
        id: safeText(info.id, previous?.id || ''),
        name: safeText(info.name, previous?.name || ''),
        creditCode: safeText(info.creditCode, previous?.creditCode || ''),
        industry: safeText(info.industry, previous?.industry || ''),
        establishDate: safeText(info.establishDate, previous?.establishDate || ''),
        address: safeText(info.address, previous?.address || ''),
        legalPerson: safeText(info.legalPerson, previous?.legalPerson || ''),
        contactPhone: safeText(info.contactPhone, previous?.contactPhone || ''),
        totalEmployees: info.totalEmployees > 0 ? info.totalEmployees : (previous?.totalEmployees || 0),
        disabledEmployees: info.disabledEmployees > 0 ? info.disabledEmployees : (previous?.disabledEmployees || 0),
        status: safeText(info.status, previous?.status || 'INACTIVE')
      };
      this.companyInfo = companyData;
      // 使用扁平State避免对象字段渲染丢失
      this.companyNameText = companyData.name;
      this.companyCreditCodeText = companyData.creditCode;
      this.companyIndustryText = companyData.industry;
      this.companyEstablishDateText = companyData.establishDate;
      this.companyAddressText = companyData.address;
      this.companyLegalPersonText = companyData.legalPerson;
      this.companyContactPhoneText = companyData.contactPhone;
      this.companyStatusText = companyData.status;
      this.totalEmployeesCount = companyData.totalEmployees;
      this.disabledEmployeesCount = companyData.disabledEmployees;
      this.syncEmployeeCounts();
    } catch (error) {
      console.error('加载单位信息失败:', error);
    }
  }



  private async viewEmployeeDetail(employee: EmployeeInfo) {
    try {
      const detail = await UnitService.getDisabledEmployeeDetail(employee.id);
      this.selectedEmployee = {
        id: employee.id,
        name: detail.name,
        idCard: detail.idCard,
        disabilityType: detail.disabilityType,
        disabilityLevel: detail.disabilityLevel,
        hireDate: detail.hireDate || '-',
        approvedDate: detail.approvedDate || '-'
      };

      // 加载该职工的残疾人证
      await this.loadDisabilityCertificate(employee.id);

      this.openSheet(CustomSheetType.EMPLOYEE_DETAIL);
    } catch (error) {
      console.error('获取职工详情失败:', error);
    }
  }

  async loadDisabilityCertificate(employeeId: string): Promise<void> {
    try {
      this.disabilityCertificate = await DisabledEmployeeService.getDisabilityCertificate(employeeId);
      if (this.disabilityCertificate) {
        console.log('已加载残疾人证:', this.disabilityCertificate.fileName);
      } else {
        console.log('该职工暂无残疾人证');
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('加载残疾人证失败:', error.message);
    }
  }

  // UnitHomePage.ets
  async handleUploadDisabilityCertificate(employeeId: string): Promise<void> {
    try {
      console.info('[上传残疾人证] 开始选择图片...');

      const photoSelectOptions = new picker.PhotoSelectOptions();
      photoSelectOptions.MIMEType = picker.PhotoViewMIMETypes.IMAGE_TYPE;
      photoSelectOptions.maxSelectNumber = 1;

      const photoPicker = new picker.PhotoViewPicker();
      const result = await photoPicker.select(photoSelectOptions);

      if (result && result.photoUris && result.photoUris.length > 0) {
        const originalUri: string = result.photoUris[0];
        console.info('[上传残疾人证] 原始URI:', originalUri);

        // 1. 定义文件名
        const fileName: string = `disability_cert_${new Date().getTime()}.jpg`;
        const context: Context = getContext(this);

        // 2. 🔴 核心修正：使用物理绝对路径进行文件操作
        // 不要在这里使用 internal:// 协议，fs 模块不识别它
        const absolutePath: string = context.cacheDir + '/' + fileName;

        console.info('[上传残疾人证] 物理目标路径:', absolutePath);
        console.info('[上传残疾人证] 开始复制文件...');

        // 3. 执行文件复制
        try {
          // 打开源文件 (picker 返回的 URI 允许 openSync)
          const srcFile = fs.openSync(originalUri, fs.OpenMode.READ_ONLY);
          // 创建目标文件 (使用绝对路径)
          const destFile = fs.openSync(absolutePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);

          // 使用文件描述符 (FD) 进行物理复制
          fs.copyFileSync(srcFile.fd, destFile.fd);

          // 记得关闭文件流
          fs.closeSync(srcFile);
          fs.closeSync(destFile);

          console.info('[上传残疾人证] 物理文件复制成功');
        } catch (fileError) {
          const err = fileError as BusinessError;
          console.error('[上传残疾人证] 文件物理操作失败:', err.code, err.message);
          throw new Error(`文件保存失败: ${err.message}`);
        }

        // 4. 验证物理文件是否存在
        if (!fs.accessSync(absolutePath)) {
          throw new Error('验证失败：物理文件未写入成功');
        }

        promptAction.showToast({
          message: '⏳ 正在上传...',
          duration: 2000
        });

        console.info('[上传残疾人证] 准备调用上传接口，传递物理路径:', absolutePath);

        // 5. 调用上传接口
        // 传递 absolutePath，HttpUtil 内部会将其转为 internal://cache/ 供上传插件识别
        const uploadResult = await DisabledEmployeeService.uploadDisabilityCertificate(
          absolutePath,
          fileName,
          employeeId
        );

        console.info('[上传残疾人证] 上传成功:', JSON.stringify(uploadResult));

        promptAction.showToast({
          message: '✅ 残疾人证上传成功',
          duration: 2000
        });

        // 刷新数据
        await this.loadDisabilityCertificate(employeeId);
        this.showUploadCertDialog = false;

      } else {
        console.info('[上传残疾人证] 用户取消选择');
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('[上传残疾人证] ========== 上传失败 ==========');
      console.error('[上传残疾人证] 错误码:', error.code);
      console.error('[上传残疾人证] 错误消息:', error.message);
      console.error('[上传残疾人证] ====================================');

      // 针对 13900002 提供更友好的提示
      const userMessage = error.code === 13900002 ? '系统找不到路径，请重试' : error.message;

      promptAction.showToast({
        message: `❌ 上传失败: ${userMessage}`,
        duration: 3000
      });
    }
  }


  async handleDeleteDisabilityCertificate(employeeId: string): Promise<void> {
    if (!this.disabilityCertificate) {
      return;
    }

    try {
      await DisabledEmployeeService.deleteDisabilityCertificate(this.disabilityCertificate.id);

      promptAction.showToast({
        message: '✅ 删除成功'
      });

      this.disabilityCertificate = null;
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      console.error('删除残疾人证失败:', error.message);
      promptAction.showToast({
        message: `❌ 删除失败: ${error.message}`
      });
    }
  }

  handleViewDisabilityCertificate(): void {
    if (!this.disabilityCertificate) {
      promptAction.showToast({
        message: '暂无残疾人证'
      });
      return;
    }

    console.info('[查看残疾人证] 文件URL:', this.disabilityCertificate.fileUrl);
    console.info('[查看残疾人证] 文件名:', this.disabilityCertificate.fileName);

    const baseUrl = 'http://10.0.2.2:8080';
    const fullImageUrl = baseUrl + this.disabilityCertificate.fileUrl;

    console.info('[查看残疾人证] 完整URL:', fullImageUrl);

    promptAction.showToast({
      message: `正在打开: ${this.disabilityCertificate.fileName}`,
      duration: 2000
    });

    // 导航到图片预览页面
    router.pushUrl({
      url: 'pages/ImagePreviewPage',
      params: {
        imageUrl: fullImageUrl,
        fileName: this.disabilityCertificate.fileName
      }
    }).catch((error: Error) => {
      console.error('导航到图片预览页面失败:', error.message);
      promptAction.showToast({
        message: '无法打开图片预览'
      });
    });
  }



  // UnitHomePage.ets
  async handleImportAllEmployees(): Promise<void> {
    try {
      const documentSelectOptions = new picker.DocumentSelectOptions();
      const docPicker = new picker.DocumentViewPicker();
      const result: Array<string> = await docPicker.select(documentSelectOptions);

      if (!result || result.length === 0) return;

      const fileUri: string = result[0];
      const fileName: string = `import_${Date.now()}.xlsx`;
      const tempPath: string = getContext(this).cacheDir + '/' + fileName;

      // 复制文件到沙箱逻辑
      const file: fs.File = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(file.fd, tempPath);
      fs.closeSync(file);

      // 🟢 统一个提示点：开始上传
      promptAction.showToast({ message: '⏳ 正在上传文件并解析...', duration: 2000 });

      const importResult: ImportResult = await UnitService.importAllEmployees(tempPath, fileName);

      if (importResult.code === 200) {
        // 🟢 解决 undefined：直接使用后端返回的详细 message
        // 后端日志里那句“成功导入 10 条...更新 10 条”就在这个字段里
        const tipMessage: string = importResult.message || '导入成功';

        promptAction.showToast({
          message: `✅ ${tipMessage}`,
          duration: 5000
        });

        // 刷新 UI
        void this.bootstrapUnitHome();
        this.isSheetShow = false;
      }
    } catch (err) {
      const error: BusinessError = err as BusinessError;
      promptAction.showToast({ message: `❌ 导入失败: ${error.message}` });
    }
  }



  //private safeGetNumber(obj: ImportStatistics, key: string): number {
    //const value: Object | undefined = (obj as Record<string, Object>)[key];
    //if (value === undefined || value === null) {
      //return 0;
    //}
   // if (typeof value === 'number') {
      //return value;
    //}
   // return 0;
  //}



  async loadDisabledEmployees() {
    try {
      const employees = await UnitService.getDisabledEmployees();
      const audits = await UnitService.getDisabledAuditApplications();
      const mappedEmployees: EmployeeInfo[] = [];
      for (let i = 0; i < employees.length; i++) {
        const e = employees[i];
        mappedEmployees.push({
          id: e.id,
          name: e.name,
          idCard: e.idCard,
          disabilityLevel: e.disabilityLevel || '三级',
          certificate: '有效',
          status: '已通过'
        });
      }
      for (let i = 0; i < audits.length; i++) {
        const a: DisabledAuditApplication = audits[i];
        if (a.status === '审批中') {
          mappedEmployees.push({
            id: `audit_${a.id}`,
            name: a.name,
            idCard: a.idCard,
            disabilityLevel: '-',
            certificate: '申请中',
            status: '审批中'
          });
        }
      }
      this.disabledEmployees = mappedEmployees;
      let approvedCount = 0;
      for (let i = 0; i < mappedEmployees.length; i++) {
        if (mappedEmployees[i].status !== '审批中') {
          approvedCount++;
        }
      }
      this.disabledEmployeesCount = approvedCount;
    } catch (error) {
      console.error('加载残疾职工失败:', error);
    }
  }

  async loadAllEmployees() {
    try {
      console.info('[加载职工列表] 开始请求 GET /unit/employees?page=1&pageSize=100');
      const result = await UnitService.getEmployees(1, 100);
      console.info('[加载职工列表] 后端返回总数:', result.total, '列表长度:', result.list.length);

      const mappedEmployees: AllEmployee[] = [];
      for (let i = 0; i < result.list.length; i++) {
        const emp = result.list[i];
        mappedEmployees.push({
          id: emp.id,
          name: emp.name,
          idCard: emp.idCard,
          hireDate: emp.hireDate
        });
      }
      this.allEmployees = mappedEmployees;
      console.info('[加载职工列表] 前端更新完成，当前列表长度:', this.allEmployees.length);

      if (this.allEmployees.length > 0) {
        console.info('[加载职工列表] 第一条记录:', this.allEmployees[0].name, this.allEmployees[0].idCard);
      }
    } catch (error) {
      console.error('加载职工列表失败:', error);
    }
  }



  async loadNonDisabledEmployees() {
    try {
      const employees = await UnitService.getNonDisabledEmployees();
      const mappedEmployees: NonDisabledEmployee[] = [];
      for (let i = 0; i < employees.length; i++) {
        const e = employees[i];
        mappedEmployees.push({
          id: e.id,
          name: e.name,
          idCard: e.idCard
        });
      }
      this.nonDisabledEmployees = mappedEmployees;
    } catch (error) {
      console.error('加载非残疾职工失败:', error);
    }
  }

  async loadApplications() {
    try {
      const result = await ReductionService.getApplications(1, 50);
      const mappedApps: ApplicationRecord[] = [];
      for (let i = 0; i < result.list.length; i++) {
        const app = result.list[i];
        mappedApps.push({
          id: app.id,
          type: app.type,
          year: app.year,
          amount: app.amount,
          status: app.status,
          date: app.date || app.submitDate || ''
        });
      }
      this.applications = mappedApps;
    } catch (error) {
      console.error('加载申请记录失败:', error);
    }
  }

  async loadPaymentInfo() {
    try {
      const stats = await PaymentService.getPaymentStatistics();
      const paymentStatsData: PaymentStats = {
        paidAmount: stats.paidAmount,
        pendingAmount: stats.pendingAmount
      };
      this.paymentStats = paymentStatsData;
      const records = await PaymentService.getPayments(1, 20);
      this.paymentRecords = records.list;
    } catch (error) {
      console.error('加载缴费信息失败:', error);
    }
  }

  async loadNotices() {
    try {
      const result = await NoticeService.getNotices(1, 20);
      this.notices = result.list;
    } catch (error) {
      console.error('加载通知单失败:', error);
    }
  }

  private openSheet(type: CustomSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    Stack() {
      Column() {
        Row() {
          Text('单位用户')
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(ColorConstants.TEXT_TITLE)
            .layoutWeight(1)

          Button() {
            SymbolGlyph($r('sys.symbol.person'))
              .fontSize(28)
              .fontColor([ColorConstants.PRIMARY])
          }
          .width(40).height(40)
          .backgroundColor('rgba(199, 28, 34, 0.1)')
          .borderRadius(20)
          .onClick(() => this.openSheet(CustomSheetType.PROFILE))
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
        .backgroundColor(ColorConstants.BG_CARD)
        .border({ width: { bottom: 1 }, color: ColorConstants.BORDER })

        Scroll() {
          Column() {
            if (this.currentTab === 'info') { this.buildUnitInfo() }
            else if (this.currentTab === 'disabled') { this.buildDisabledEmployees() }
            else if (this.currentTab === 'application') { this.buildApplication() }
            else if (this.currentTab === 'payment') { this.buildPaymentRecords() }
            else if (this.currentTab === 'notice') { this.buildNotices() }
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 16, bottom: 80 })
        }
        .layoutWeight(1)
        .backgroundColor(ColorConstants.BG_PAGE)

        this.buildBottomTabBar()
      }
      .width('100%').height('100%')
    }
    .bindSheet($$this.isSheetShow, this.sheetBuilder(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = CustomSheetType.NONE;
      }
    })
  }

  @Builder
  sheetBuilder() {
    if (this.activeSheet === CustomSheetType.ALL_EMPLOYEES || this.activeSheet === CustomSheetType.ADD_DISABLED) {
      Column() {
        if (this.activeSheet === CustomSheetType.ALL_EMPLOYEES) {
          this.buildAllEmployeesDialog()
        } else {
          this.buildAddDisabledDialog()
        }
      }
      .width('100%')
      .height('88%')
      .padding({ top: 12 })
    } else {
      Column() {
        if (this.activeSheet === CustomSheetType.PROFILE) {
          this.buildProfileSheet()
        } else if (this.activeSheet === CustomSheetType.EDIT_PROFILE) {
          this.buildEditProfileDialog()
        } else if (this.activeSheet === CustomSheetType.EMPLOYEE_DETAIL) {
          this.buildEmployeeDetailDialog()
        } else if (this.activeSheet === CustomSheetType.APP_FORM) {
          this.buildApplicationFormDialog()
        } else if (this.activeSheet === CustomSheetType.APP_DETAIL) {
          this.buildApplicationDetailDialog()
        } else if (this.activeSheet === CustomSheetType.NOTICE_DETAIL) {
          this.buildNoticeDetailDialog()
        } else if (this.activeSheet === CustomSheetType.ADD_EMPLOYEE) {
          this.buildAddEmployeeDialog()
        }
      }
      .padding({ top: 20 })
    }
  }

  @Builder
  buildBottomTabBar() {
    Row() {
      ForEach(this.tabs, (tab: TabItem) => {
        Column() {
          SymbolGlyph($r(`sys.symbol.${tab.icon}`))
            .fontSize(24)
            .fontColor([this.currentTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY])
          Text(tab.name)
            .fontSize(11)
            .fontColor(this.currentTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
            .margin({ top: 4 })
        }
        .layoutWeight(1)
        .height(56)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.currentTab = tab.id;
          if (tab.id === 'info') {
            this.loadCompanyInfo();
            this.syncEmployeeCounts();
          }
        })
      })
    }
    .width('100%')
    .backgroundColor(ColorConstants.BG_CARD)
    .border({ width: { top: 1 }, color: ColorConstants.BORDER })
  }

  @Builder
  buildUnitInfo() {
    Column() {
      Column() {
        Row() {
          SymbolGlyph($r('sys.symbol.building_fill')).fontSize(32).fontColor([ColorConstants.PRIMARY])
          Column() {
            Text(this.companyNameText || '加载中...').fontSize(18).fontWeight(FontWeight.Bold)
            Text(`统一社会信用代码：${this.companyCreditCodeText || '-'}`).fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
        }
        Divider().color(ColorConstants.BORDER).margin({ top: 16, bottom: 16 })
        Row() {
          Text('所属行业').fontColor(ColorConstants.TEXT_SECONDARY).width(100)
          Text(this.companyIndustryText ? this.companyIndustryText : '-')
            .fontColor(ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
        }.padding({ top: 8, bottom: 8 })
        Row() {
          Text('成立日期').fontColor(ColorConstants.TEXT_SECONDARY).width(100)
          Text(this.companyEstablishDateText ? this.companyEstablishDateText : '-')
            .fontColor(ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
        }.padding({ top: 8, bottom: 8 })
        Row() {
          Text('注册地址').fontColor(ColorConstants.TEXT_SECONDARY).width(100)
          Text(this.companyAddressText ? this.companyAddressText : '-')
            .fontColor(ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
        }.padding({ top: 8, bottom: 8 })
        Row() {
          Text('法定代表人').fontColor(ColorConstants.TEXT_SECONDARY).width(100)
          Text(this.companyLegalPersonText ? this.companyLegalPersonText : '-')
            .fontColor(ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
        }.padding({ top: 8, bottom: 8 })
        Row() {
          Text('联系电话').fontColor(ColorConstants.TEXT_SECONDARY).width(100)
          Text(this.companyContactPhoneText ? this.companyContactPhoneText : '-')
            .fontColor(ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
        }.padding({ top: 8, bottom: 8 })
        this.buildInfoRow('在职职工', `${this.totalEmployeesCount}人`)
        this.buildInfoRow('残疾职工', `${this.disabledEmployeesCount}人`)
        this.buildInfoRow(
          '单位状态',
          this.isCompanyActive() ? '正常' : '异常',
          this.isCompanyActive() ? ColorConstants.SUCCESS : ColorConstants.DANGER
        )

        Row() {
          Button('新增职工')
            .layoutWeight(1).height(44).margin({ top: 16, right: 8 })
            .backgroundColor(ColorConstants.PRIMARY).fontColor(ColorConstants.BG_CARD)
            .onClick(() => this.openSheet(CustomSheetType.ADD_EMPLOYEE))
          Button('查看全体职工')
            .layoutWeight(1).height(44).margin({ top: 16, left: 8 })
            .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
            .onClick(() => {
              void this.openAllEmployeesSheet();
            })
        }.width('100%')
      }
      .padding(16).backgroundColor(ColorConstants.BG_CARD).borderRadius(12)
    }
  }

  @Builder
  buildDisabledEmployees() {
    Column() {
      Row() {
        Text('职工列表').fontSize(16).fontWeight(FontWeight.Bold).layoutWeight(1)
        Button('新增残疾职工')
          .height(36).fontSize(13)
          .backgroundColor(ColorConstants.PRIMARY).fontColor(ColorConstants.BG_CARD)
          .onClick(() => {
            this.selectedNonDisabledEmployees = [];
            this.newDisabilityAttachment = '';
            this.newDisabilityLevel = '';
            this.loadNonDisabledEmployees();
            this.openSheet(CustomSheetType.ADD_DISABLED);
          })
      }.width('100%').margin({ bottom: 12 })

      if (this.disabledEmployees.length === 0) {
        Column() {
          Text('暂无残疾职工数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.disabledEmployees, (employee: EmployeeInfo) => {
          Row() {
            Column() {
              Text(employee.name).fontSize(15).fontWeight(FontWeight.Medium)
              Text(employee.idCard).fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`状态：${employee.status || '已通过'}`)
                .fontSize(12)
                .fontColor(employee.status === '审批中' ? ColorConstants.WARNING : ColorConstants.SUCCESS)
                .margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)

            if (employee.status === '审批中') {
              Text('申请中')
                .fontSize(12)
                .fontColor(ColorConstants.WARNING)
            } else {
              Button('详情').height(32).fontSize(12)
                .onClick(() => this.viewEmployeeDetail(employee))
            }
          }
          .padding(16).backgroundColor(ColorConstants.BG_CARD).borderRadius(12).margin({ bottom: 10 })
        })
      }
    }
  }



  @Builder
  buildApplication() {
    Column() {
      Button('提交减免缓申请')
        .width('100%').height(48).backgroundColor(ColorConstants.PRIMARY)
        .onClick(() => this.openSheet(CustomSheetType.APP_FORM))
        .margin({ bottom: 16 })

      Text('申请历史').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })

      if (this.applications.length === 0) {
        Column() {
          Text('暂无申请记录')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.applications, (record: ApplicationRecord) => {
          Column() {
            Row() {
              Text(`${record.year}${record.type}申请`)
                .fontWeight(FontWeight.Medium)
                .layoutWeight(1)
              Text(record.status)
                .fontColor(this.getApplicationStatusColor(record.status))
            }
            Text(`申请金额：${record.amount}`)
              .fontSize(12)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .margin({ top: 8 })
            Text(`提交时间：${record.date}`)
              .fontSize(12)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .margin({ top: 4 })
            Button('查看详情').width('100%').height(36).margin({ top: 12 })
              .onClick(() => {
                void this.viewApplicationDetail(record);
              })
          }
          .padding(16).backgroundColor(ColorConstants.BG_CARD).borderRadius(12).margin({ bottom: 12 })
        })
      }
    }
  }

  @Builder
  buildPaymentRecords() {
    Column() {
      Row() {
        Column() {
          Text(`￥${this.paymentStats.paidAmount.toLocaleString()}`).fontSize(22).fontWeight(FontWeight.Bold).fontColor(ColorConstants.PRIMARY)
          Text('本年度已缴').fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)

        Column() {
          Text(`￥${this.paymentStats.pendingAmount.toLocaleString()}`).fontSize(22).fontWeight(FontWeight.Bold).fontColor(ColorConstants.WARNING)
          Text('待缴金额').fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
        }.layoutWeight(1).alignItems(HorizontalAlign.Center)
      }
      .width('100%').padding(16)
      .backgroundColor(ColorConstants.BG_CARD).borderRadius(12)
      .border({ width: 1, color: ColorConstants.BORDER }).margin({ bottom: 16 })

      Text('缴费记录').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 12 })

      if (this.paymentRecords.length === 0) {
        Column() {
          Text('暂无缴费记录')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.paymentRecords, (record: PaymentRecord, index: number) => {
          Row() {
            Column() {
              Text(record.period).fontSize(15).fontWeight(FontWeight.Medium)
              Text(`缴费日期：${record.date}`).fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)

            Column() {
              Text(record.amount).fontSize(16).fontWeight(FontWeight.Bold)
              Text(record.status).fontSize(12).fontColor(ColorConstants.SUCCESS).margin({ top: 4 })
            }.alignItems(HorizontalAlign.End)
          }
          .width('100%').padding(16)
          .backgroundColor(ColorConstants.BG_CARD).borderRadius(12)
          .border({ width: 1, color: ColorConstants.BORDER }).margin({ bottom: 12 })
        })
      }
    }
    .width('100%')
  }

  @Builder
  buildNotices() {
    Column() {
      if (this.notices.length === 0) {
        Column() {
          Text('暂无通知单')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .padding(32)
        .justifyContent(FlexAlign.Center)
      } else {
        ForEach(this.notices, (notice: NoticeItem) => {
          Row() {
            Column() {
              Text(notice.title || '通知详情')
                .fontSize(16)
                .fontWeight(FontWeight.Medium)
                .fontColor(ColorConstants.TEXT_TITLE)
              Row() {
                Text(notice.type || '通知单')
                  .fontSize(12)
                  .fontColor(ColorConstants.PRIMARY)
                Text(notice.date || '')
                  .fontSize(12)
                  .fontColor(ColorConstants.TEXT_SECONDARY)
                  .margin({ left: 10 })
              }
              .margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            SymbolGlyph($r('sys.symbol.chevron_right'))
              .fontColor([ColorConstants.TEXT_SECONDARY])
          }
          .padding(16).backgroundColor(ColorConstants.BG_CARD).borderRadius(12).margin({ bottom: 12 })
          .onClick(() => this.viewNoticeDetail(notice))
        })
      }
    }
  }

  @Builder
  buildProfileSheet() {
    Column() {
      Row() {
        Circle().width(60).height(60).fill('rgba(199, 28, 34, 0.1)')
        Column() {
          Text(appViewModel.currentUser?.realName || '单位管理员').fontSize(18).fontWeight(FontWeight.Bold)
          Text(`ID: ${appViewModel.currentUser?.username || ''}`).fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY)
        }.margin({ left: 16 }).layoutWeight(1)
      }.padding(20).backgroundColor('rgba(199, 28, 34, 0.05)').borderRadius(12)

      List() {
        ListItem() {
          Row() {
            Text('修改账号信息').layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
          }
          .height(56).padding({ left: 16, right: 16 })
          .onClick(() => {
            this.editUsername = appViewModel.currentUser?.username || '';
            this.editOldPassword = '';
            this.editPassword = '';
            this.editConfirmPassword = '';
            this.editError = '';
            this.activeSheet = CustomSheetType.EDIT_PROFILE;
          })
        }
        ListItem() {
          Row() {
            Text('退出登录').fontColor(ColorConstants.DANGER).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
          }
          .height(56).padding({ left: 16, right: 16 })
          .onClick(() => this.handleLogout())
        }
      }
      .backgroundColor(ColorConstants.BG_CARD).borderRadius(12).margin({ top: 20 })
    }
    .padding(16)
  }

  @Builder
  buildEditProfileDialog() {
    Column() {
      Text('用户名（不可修改）')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 })

      TextInput({ placeholder: '用户名', text: this.editUsername })
        .enabled(false)
        .margin({ bottom: 12 })
        .onChange(v => this.editUsername = v)

      Text('旧密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 })
      TextInput({ placeholder: '请输入旧密码', text: this.editOldPassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange(v => {
          this.editOldPassword = v;
          this.editError = '';
        })

      Text('新密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 })
      TextInput({ placeholder: '请输入新密码', text: this.editPassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange(v => {
          this.editPassword = v;
          this.editError = '';
        })

      Text('确认新密码')
        .fontSize(12)
        .fontColor(ColorConstants.TEXT_SECONDARY)
        .width('100%')
        .margin({ bottom: 6 })
      TextInput({ placeholder: '请再次输入新密码', text: this.editConfirmPassword })
        .type(InputType.Password)
        .margin({ bottom: 12 })
        .onChange(v => {
          this.editConfirmPassword = v;
          this.editError = '';
        })

      if (this.editError) {
        Text(this.editError)
          .fontSize(12)
          .fontColor(ColorConstants.DANGER)
          .margin({ bottom: 12 })
      }

      Button(this.editSaving ? '保存中...' : '保存修改')
        .width('100%')
        .enabled(!this.editSaving)
        .onClick(() => this.handleSaveProfile())
    }.padding(20)
  }

  @Builder
  buildAllEmployeesDialog() {
    Column() {
      Text('全体职工')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConstants.TEXT_TITLE)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 10 })

      if (this.allEmployees.length === 0) {
        Text('暂无职工数据')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .padding(20)
      } else {
        Scroll() {
          Column({ space: 8 }) {
            ForEach(this.allEmployees, (emp: AllEmployee) => {
              Row() {
                Column() {
                  Text(emp.name)
                    .fontSize(15)
                    .fontWeight(FontWeight.Medium)
                    .fontColor(ColorConstants.TEXT_TITLE)

                  Text(`编号：${emp.id}`)
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ top: 4 })

                  Text(`入职时间：${emp.hireDate ?? '-'}`)
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ top: 2 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text(emp.idCard)
                  .fontSize(13)
                  .fontColor(ColorConstants.TEXT_BODY)
              }
              .width('100%')
              .padding(12)
              .backgroundColor(ColorConstants.BG_CARD)
              .borderRadius(8)
              .border({ width: 1, color: ColorConstants.BORDER })
            }, (emp: AllEmployee) => `${emp.id}_${emp.idCard}`)
          }
          .width('100%')
          .padding({ left: 20, right: 20, bottom: 24 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .nestedScroll({
          scrollForward: NestedScrollMode.SELF_FIRST,
          scrollBackward: NestedScrollMode.SELF_FIRST
        })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ bottom: 8 })
  }

  @Builder
  buildEmployeeDetailDialog() {
    Column() {
      // 关闭按钮
      Row() {
        Text('职工详情')
          .fontSize(17)
          .fontWeight(FontWeight.Bold)
          .fontColor(ColorConstants.TEXT_TITLE)
          .layoutWeight(1)

        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(20)
            .fontColor([ColorConstants.TEXT_SECONDARY])
        }
        .width(32)
        .height(32)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(16)
        .onClick(() => this.isSheetShow = false)
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 12 })

      // 滚动内容区域
      Scroll() {
        Column() {
          if (this.selectedEmployee) {
            this.buildDetailRow('姓名', this.selectedEmployee.name)
            this.buildDetailRow('身份证号', this.selectedEmployee.idCard)
            this.buildDetailRow('残疾类别', this.selectedEmployee.disabilityType)
            this.buildDetailRow('残疾等级', this.selectedEmployee.disabilityLevel)
            this.buildDetailRow('入职时间', this.selectedEmployee.hireDate)
            this.buildDetailRow('审核通过时间', this.selectedEmployee.approvedDate)

            Divider().color(ColorConstants.BORDER).margin({ top: 16, bottom: 16 })

            Text('残疾人证').fontSize(16).fontWeight(FontWeight.Bold).fontColor(ColorConstants.TEXT_TITLE)
              .width('100%').margin({ bottom: 12 })

            if (this.disabilityCertificate) {
              Column() {
                Row() {
                  SymbolGlyph($r('sys.symbol.doc')).fontSize(24).fontColor([ColorConstants.PRIMARY])
                  Column() {
                    Text(this.disabilityCertificate.fileName)
                      .fontSize(14)
                      .fontColor(ColorConstants.TEXT_TITLE)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.disabilityCertificate.fileSize)
                      .fontSize(12)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                      .margin({ top: 4 })
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)
                  .margin({ left: 12 })

                  Button('查看')
                    .height(32)
                    .fontSize(12)
                    .backgroundColor('rgba(199, 28, 34, 0.1)')
                    .fontColor(ColorConstants.PRIMARY)
                    .margin({ right: 8 })
                    .onClick(() => this.handleViewDisabilityCertificate())

                  Button('删除')
                    .height(32)
                    .fontSize(12)
                    .backgroundColor('rgba(255, 0, 0, 0.1)')
                    .fontColor(ColorConstants.DANGER)
                    .onClick(() => this.handleDeleteDisabilityCertificate(this.selectedEmployee!.id))
                }
                .width('100%')
                .padding(12)
                .backgroundColor(ColorConstants.BG_PAGE)
                .borderRadius(8)
              }
              .width('100%')
              .margin({ bottom: 16 })
            } else {
              Column() {
                SymbolGlyph($r('sys.symbol.doc')).fontSize(48).fontColor([ColorConstants.TEXT_SECONDARY])
                Text('暂无残疾人证')
                  .fontSize(14)
                  .fontColor(ColorConstants.TEXT_SECONDARY)
                  .margin({ top: 8 })
                Text('点击下方按钮上传')
                  .fontSize(12)
                  .fontColor(ColorConstants.TEXT_SECONDARY)
                  .margin({ top: 4 })
              }
              .width('100%')
              .padding(24)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
              .justifyContent(FlexAlign.Center)
              .margin({ bottom: 16 })
            }

            Button('上传/更换残疾人证')
              .width('100%')
              .height(44)
              .fontSize(14)
              .backgroundColor(ColorConstants.PRIMARY)
              .fontColor(ColorConstants.BG_CARD)
              .onClick(() => void this.handleUploadDisabilityCertificate(this.selectedEmployee!.id))
          } else {
            Text('暂无数据')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .padding(20)
          }
        }
        .width('100%')
        .padding({ left: 20, right: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
      .nestedScroll({
        scrollForward: NestedScrollMode.PARENT_FIRST,
        scrollBackward: NestedScrollMode.PARENT_FIRST
      })

      // 底部固定按钮
      Row() {
        Button('关闭')
          .layoutWeight(1).height(44).fontSize(16)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .backgroundColor(ColorConstants.BG_PAGE)
          .border({ width: 1, color: ColorConstants.BORDER })
          .borderRadius(8).margin({ right: 8 })
          .onClick(() => this.isSheetShow = false)
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 12, bottom: 20 })
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildApplicationFormDialog() {
    Scroll() {
      Column() {
        Text('申请类型').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        Row() {
          Button('减')
            .layoutWeight(1).height(44)
            .fontColor(this.appFormType === '减' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.appFormType === '减' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ right: 4 })
            .onClick(() => { this.appFormType = '减'; })
          Button('免')
            .layoutWeight(1).height(44)
            .fontColor(this.appFormType === '免' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.appFormType === '免' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ left: 4, right: 4 })
            .onClick(() => { this.appFormType = '免'; })
          Button('缓')
            .layoutWeight(1).height(44)
            .fontColor(this.appFormType === '缓' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.appFormType === '缓' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ left: 4 })
            .onClick(() => { this.appFormType = '缓'; })
        }.width('100%').margin({ bottom: 16 })

        Text('申请年份').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        TextInput({ placeholder: '请输入年份', text: this.appFormYear })
          .onChange(v => this.appFormYear = v)
          .width('100%').height(44).fontSize(14)
          .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 16 })

        Text('申请金额').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        TextInput({ placeholder: '请输入金额', text: this.appFormAmount })
          .onChange(v => this.appFormAmount = v)
          .type(InputType.Number)
          .width('100%').height(44).fontSize(14)
          .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
          .padding({ left: 12, right: 12 })
          .margin({ bottom: 16 })

        Text('申请理由').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        TextArea({ placeholder: '请详细说明申请理由', text: this.appFormReason })
          .onChange(v => this.appFormReason = v)
          .width('100%').height(120).fontSize(14)
          .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
          .padding(12)
          .margin({ bottom: 16 })

        Text('附件上传').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        Row() {
          Text(this.appFormAttachment || '点击选择附件')
            .fontSize(14)
            .fontColor(this.appFormAttachment ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
            .layoutWeight(1)
          Button('上传')
            .height(36).fontSize(13)
            .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
            .onClick(() => void this.handleUploadReductionAttachment())
        }
        .width('100%').height(44)
        .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .layoutWeight(1).height(44).fontSize(16)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8).margin({ right: 8 })
            .onClick(() => { this.isSheetShow = false; })
          Button('提交')
            .layoutWeight(1).height(44).fontSize(16)
            .fontColor(ColorConstants.BG_CARD)
            .backgroundColor(ColorConstants.PRIMARY)
            .borderRadius(8).margin({ left: 8 })
            .onClick(() => void this.submitApplication())
        }.width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
  }

  @Builder
  buildApplicationDetailDialog() {
    Scroll() {
      Column() {
        if (this.selectedApplication) {
          Row() {
            Row() {
              Text(this.selectedApplication.type)
                .fontSize(12)
                .fontColor(ColorConstants.BG_CARD)
                .backgroundColor(ColorConstants.PRIMARY)
                .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                .borderRadius(12)
              Text(this.selectedApplication.status)
                .fontSize(12)
                .fontColor(this.selectedApplication.status === '已通过' ? ColorConstants.SUCCESS :
                  this.selectedApplication.status === '已驳回' ? ColorConstants.DANGER : ColorConstants.WARNING)
                .margin({ left: 8 })
            }.layoutWeight(1)

            Text(this.selectedApplication.submitDate)
              .fontSize(12)
              .fontColor(ColorConstants.TEXT_SECONDARY)
          }.width('100%').margin({ bottom: 20 })

          Divider().color(ColorConstants.BORDER).margin({ bottom: 20 })

          this.buildDetailRow('申请类型', this.selectedApplication.type)
          this.buildDetailRow('申请年份', this.selectedApplication.year)
          this.buildDetailRow('申请金额', '￥' + this.selectedApplication.amount)
          this.buildDetailRow('提交日期', this.selectedApplication.submitDate)

          Divider().color(ColorConstants.BORDER).margin({ top: 12, bottom: 12 })

          Text('申请理由').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          Text(this.selectedApplication.reason || '无')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_BODY)
            .lineHeight(22)
            .padding(12)
            .backgroundColor(ColorConstants.BG_PAGE)
            .borderRadius(8)
            .width('100%')
            .margin({ bottom: 16 })

          Text('附件').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          Row() {
            SymbolGlyph($r('sys.symbol.doc')).fontSize(16).fontColor([ColorConstants.TEXT_SECONDARY])
            Text(this.selectedApplication.attachment || '无附件')
              .fontSize(14)
              .fontColor(this.selectedApplication.attachment ? ColorConstants.PRIMARY : ColorConstants.TEXT_SECONDARY)
              .margin({ left: 8 })
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 20 })

          Row() {
            Button('撤销申请')
              .layoutWeight(1).height(44).fontSize(14)
              .fontColor(ColorConstants.DANGER)
              .backgroundColor('rgba(255, 0, 0, 0.08)')
              .border({ width: 1, color: 'rgba(255, 0, 0, 0.2)' })
              .borderRadius(8)
              .enabled(this.selectedApplication.status === '待审核' || this.selectedApplication.status === '审批中')
              .opacity(this.selectedApplication.status === '待审核' || this.selectedApplication.status === '审批中' ? 1 : 0.4)
              .onClick(() => void this.handleCancelApplication())
          }.width('100%')
        } else {
          Text('暂无数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .padding(20)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 20 })
    }
    .width('100%')
  }

  @Builder
  buildNoticeDetailDialog() {
    Scroll() {
      Column() {
        if (this.selectedNotice) {
          Row() {
            Text(this.selectedNotice.type || '通知单')
              .fontSize(12)
              .fontColor(ColorConstants.BG_CARD)
              .backgroundColor(ColorConstants.PRIMARY)
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .borderRadius(12)
            Text(this.selectedNotice.date)
              .fontSize(12)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .margin({ left: 12 })
          }.width('100%').margin({ bottom: 16 })

          Text(this.selectedNotice.content || '暂无通知内容')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_BODY)
            .lineHeight(24)
        } else {
          Text('暂无数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
  }

  @Builder
  buildAddEmployeeDialog() {
    Scroll() {
      Column() {
        Text('添加方式').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
        Row() {
          Button('手动添加')
            .layoutWeight(1).height(44)
            .fontColor(this.addEmployeeMode === '手动添加' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.addEmployeeMode === '手动添加' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ right: 4 })
            .onClick(() => { this.addEmployeeMode = '手动添加'; })
          Button('批量导入')
            .layoutWeight(1).height(44)
            .fontColor(this.addEmployeeMode === '批量导入' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.addEmployeeMode === '批量导入' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ left: 4 })
            .onClick(() => { this.addEmployeeMode = '批量导入'; })
        }.width('100%').margin({ bottom: 16 })

        if (this.addEmployeeMode === '手动添加') {
          Text('姓名').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          TextInput({ placeholder: '请输入姓名', text: this.newEmployeeName })
            .onChange(v => this.newEmployeeName = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 16 })

          Text('身份证号').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          TextInput({ placeholder: '请输入身份证号', text: this.newEmployeeIdCard })
            .onChange(v => this.newEmployeeIdCard = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 16 })

          Text('入职时间').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          TextInput({ placeholder: '请输入入职时间', text: this.newEmployeeHireDate })
            .onChange(v => this.newEmployeeHireDate = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 24 })
        } else {
          Column() {
            SymbolGlyph($r('sys.symbol.doc')).fontSize(48).fontColor([ColorConstants.TEXT_SECONDARY])
            Text('点击上传Excel文件').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 12 })
            Text('支持.xls、.xlsx格式').fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
          }
          .width('100%').height(120)
          .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
          .border({ width: 1, color: ColorConstants.BORDER, style: BorderStyle.Dashed })
          .justifyContent(FlexAlign.Center)
          .margin({ bottom: 24 })
          .onClick(() => {
            this.handleImportAllEmployees();  // ✅ 调用实际的导入方法
          })
        }

        Row() {
          Button('取消')
            .layoutWeight(1).height(44).fontSize(16)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8).margin({ right: 8 })
            .onClick(() => { this.isSheetShow = false; })
          Button('确定')
            .layoutWeight(1).height(44).fontSize(16)
            .fontColor(ColorConstants.BG_CARD)
            .backgroundColor(ColorConstants.PRIMARY)
            .borderRadius(8).margin({ left: 8 })
            .onClick(() => this.handleAddEmployee())
        }.width('100%')
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
  }

  @Builder
  buildAddDisabledDialog() {
    Column() {
      Text('新增残疾职工')
        .fontSize(17)
        .fontWeight(FontWeight.Bold)
        .fontColor(ColorConstants.TEXT_TITLE)
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 10 })

      Scroll() {
        Column() {
          Text('选择职工').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })

          if (this.nonDisabledEmployees.length === 0) {
            Text('暂无可添加的职工')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .padding(20)
          } else {
            ForEach(this.nonDisabledEmployees, (emp: NonDisabledEmployee, index: number) => {
              Row() {
                Checkbox({ name: emp.name, group: 'disabledGroup' })
                  .onChange((value: boolean) => {
                    if (value) {
                      if (!this.selectedNonDisabledEmployees.includes(emp.id)) {
                        this.selectedNonDisabledEmployees.push(emp.id);
                      }
                    } else {
                      this.selectedNonDisabledEmployees = this.selectedNonDisabledEmployees.filter(id => id !== emp.id);
                    }
                  })

                Column() {
                  Text(emp.name).fontSize(14).fontWeight(FontWeight.Medium)
                  Text(emp.idCard).fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY)
                }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
              }
              .width('100%').padding(12)
              .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
              .margin({ bottom: 8 })
            })
          }

          Text('残疾类型').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8, top: 16 })
          TextInput({ placeholder: '请输入残疾类型', text: this.newDisabilityType })
            .onChange(v => this.newDisabilityType = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 16 })

          Text('残疾等级').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          Row() {
            ForEach(['一级', '二级', '三级', '四级'], (level: string, index: number) => {
              Button(level)
                .layoutWeight(1).height(44).fontSize(13)
                .fontColor(this.newDisabilityLevel === level ? ColorConstants.BG_CARD : ColorConstants.TEXT_SECONDARY)
                .backgroundColor(this.newDisabilityLevel === level ? ColorConstants.PRIMARY : ColorConstants.BORDER)
                .borderRadius(8)
                .margin({ left: index === 0 ? 0 : 4, right: index === 3 ? 0 : 4 })
                .onClick(() => { this.newDisabilityLevel = level; })
            })
          }.width('100%').margin({ bottom: 16 })

          Text('附件上传').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          Row() {
            Text(this.newDisabilityAttachment || '请在职工详情中上传残疾人证')
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .layoutWeight(1)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Button('说明')
              .height(36).fontSize(12)
              .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
              .onClick(() => {
                promptAction.showDialog({
                  title: '残疾人证上传说明',
                  message: '批量添加职工时不需要上传残疾人证。\n\n添加完成后，请在"残疾职工"列表中点击职工详情的"上传/更换残疾人证"按钮进行上传。\n\n支持格式：JPG、PNG、GIF\n最大大小：10MB',
                  buttons: [
                    {
                      text: '知道了',
                      color: ColorConstants.PRIMARY
                    }
                  ]
                });
              })
          }
          .width('100%')
          .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
          .padding({ left: 12, right: 12, top: 8, bottom: 8 })
          .margin({ bottom: 24 })

          Row() {
            Button('取消')
              .layoutWeight(1).height(44).fontSize(16)
              .fontColor(ColorConstants.TEXT_SECONDARY)
              .backgroundColor(ColorConstants.BG_PAGE)
              .border({ width: 1, color: ColorConstants.BORDER })
              .borderRadius(8).margin({ right: 8 })
              .onClick(() => { this.isSheetShow = false; })
            Button('确定')
              .layoutWeight(1).height(44).fontSize(16)
              .fontColor(ColorConstants.BG_CARD)
              .backgroundColor(ColorConstants.PRIMARY)
              .borderRadius(8).margin({ left: 8 })
              .onClick(() => this.handleAddDisabledEmployee())
          }.width('100%')
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
      .nestedScroll({
        scrollForward: NestedScrollMode.SELF_FIRST,
        scrollBackward: NestedScrollMode.SELF_FIRST
      })
    }
    .width('100%')
    .height('100%')
  }



  private async viewApplicationDetail(record: ApplicationRecord) {
    try {
      const detail = await ReductionService.getApplicationDetail(record.id);
      const rawAmount = (detail.amount || '').replace('￥', '').replace('¥', '').replace(',', '');
      this.selectedApplication = {
        id: detail.id,
        type: detail.type,
        year: detail.year,
        amount: rawAmount,
        reason: detail.reason || '',
        attachment: detail.attachment || '',
        status: detail.status,
        submitDate: detail.submitDate || detail.date || ''
      };
      this.openSheet(CustomSheetType.APP_DETAIL);
    } catch (error) {
      console.error('获取申请详情失败:', error);
      this.showToastSafe('获取申请详情失败');
    }
  }

  private async viewNoticeDetail(notice: NoticeItem) {
    try {
      const detail = await NoticeService.getNoticeDetail(notice.id);
      this.selectedNotice = detail as NoticeDetail;
      this.openSheet(CustomSheetType.NOTICE_DETAIL);
      if (!notice.read) {
        await NoticeService.markAsRead(notice.id);
        this.loadNotices();
      }
    } catch (error) {
      console.error('获取通知详情失败:', error);
    }
  }

  private async handleSaveProfile() {
    const user = appViewModel.currentUser;
    if (!user) {
      this.editError = '用户未登录';
      return;
    }
    if (!this.editOldPassword.trim()) {
      this.editError = '请输入旧密码';
      return;
    }
    if (!this.editPassword.trim()) {
      this.editError = '请输入新密码';
      return;
    }
    if (this.editPassword.length < 6) {
      this.editError = '新密码长度不能少于6位';
      return;
    }
    if (!this.editConfirmPassword.trim()) {
      this.editError = '请确认新密码';
      return;
    }
    if (this.editPassword !== this.editConfirmPassword) {
      this.editError = '两次输入的新密码不一致';
      return;
    }

    this.editSaving = true;
    this.editError = '';
    try {
      await AuthService.changePassword(
        user.id,
        'company',
        this.editOldPassword,
        this.editPassword,
        this.editConfirmPassword
      );
      this.isSheetShow = false;
      this.activeSheet = CustomSheetType.NONE;
      this.editOldPassword = '';
      this.editPassword = '';
      this.editConfirmPassword = '';
      promptAction.showToast({ message: '密码修改成功' });
    } catch (error) {
      this.editError = error instanceof Error ? error.message : '修改失败，请重试';
    } finally {
      this.editSaving = false;
    }
  }

  private handleLogout() {
    this.isSheetShow = false;
    appViewModel.logout();
    AppStorage.setOrCreate('token', '');
    router.replaceUrl({ url: 'pages/LoginPage' });
  }


  private async handleUploadReductionAttachment(): Promise<void> {
    try {
      console.log('=== 开始选择减免缓附件 ===');

      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions();
      documentSelectOptions.maxSelectNumber = 1;
      documentSelectOptions.fileSuffixFilters = [
        // 图片格式
        '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp',
        // 文档格式
        '.pdf', '.doc', '.docx', '.txt', '.rtf',
        // Excel 格式
        '.xls', '.xlsx','.csv'
      ];

      const docPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker();
      const result: Array<string> = await docPicker.select(documentSelectOptions);

      if (!result || result.length === 0) {
        console.log('用户取消选择文件');
        return;
      }

      const fileUri: string = result[0];
      console.log('选择的文件URI:', fileUri);

      // 从 URI 中提取原始文件扩展名
      const lastDotIndex = fileUri.lastIndexOf('.');
      const extension = lastDotIndex !== -1 ? fileUri.substring(lastDotIndex) : '.pdf';
      const fileName: string = `reduction_${Date.now()}${extension}`;

      const context: Context = getContext(this) as Context;
      const tempPath: string = context.cacheDir + '/' + fileName;

      console.log('开始将文件转存至沙箱...');
      const file: fs.File = fs.openSync(fileUri, fs.OpenMode.READ_ONLY);
      fs.copyFileSync(file.fd, tempPath);
      fs.closeSync(file);
      console.log('文件已转存至沙箱:', tempPath);

      promptAction.showToast({ message: '⏳ 正在上传附件...', duration: 2000 });

      const attachmentUrl: string = await UnitService.uploadReductionAttachment(tempPath, fileName);

      this.appFormAttachment = attachmentUrl;

      promptAction.showToast({
        message: '✅ 附件上传成功',
        duration: 2000
      });

      console.log('附件URL:', attachmentUrl);

      try {
        if (fs.accessSync(tempPath)) {
          fs.unlinkSync(tempPath);
          console.log('临时文件已清理');
        }
      } catch (e) {
        console.warn('清理临时文件失败:', e);
      }

    } catch (err) {
      const error: BusinessError = err instanceof Error ? err as BusinessError : new Error(String(err)) as BusinessError;
      console.error('附件上传失败:', error.message);
      promptAction.showToast({
        message: `❌ 附件上传失败: ${error.message}`,
        duration: 3000
      });
    }
  }


  private async submitApplication() {
    try {
      if (!this.appFormYear.trim()) {
        this.showToastSafe('请输入申请年份');
        return;
      }
      if (!this.appFormAmount.trim()) {
        this.showToastSafe('请输入申请金额');
        return;
      }
      if (!this.appFormReason.trim()) {
        this.showToastSafe('请输入申请理由');
        return;
      }
      const appData: ApplicationSubmitData = {
        type: this.appFormType,
        year: this.appFormYear,
        amount: this.appFormAmount,
        reason: this.appFormReason,
        attachment: this.appFormAttachment
      };
      await ReductionService.submitApplication(appData);
      this.appFormAmount = '';
      this.appFormReason = '';
      this.appFormAttachment = '';
      await this.loadApplications();
      this.showToastSafe('申请提交成功');
      this.isSheetShow = false;
    } catch (error) {
      console.error('提交申请失败:', error);
      this.showToastSafe('提交申请失败，请重试');
    }
  }

  private async handleCancelApplication() {
    if (!this.selectedApplication) {
      this.showToastSafe('未选择申请记录');
      return;
    }

    const canCancel: boolean = this.selectedApplication.status === '待审核' || this.selectedApplication.status === '审批中';
    if (!canCancel) {
      this.showToastSafe('当前状态不可撤销');
      return;
    }

    promptAction.showDialog({
      title: '确认撤销',
      message: `确定要撤销${this.selectedApplication.year}年${this.selectedApplication.type}申请吗？撤销后不可恢复。`,
      buttons: [
        {
          text: '取消',
          color: ColorConstants.TEXT_SECONDARY
        },
        {
          text: '确认撤销',
          color: ColorConstants.DANGER
        }
      ]
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        void this.doCancelApplication();
      }
    }).catch((err: Error) => {
      console.error('显示确认对话框失败:', err);
    });
  }

  private async doCancelApplication() {
    if (!this.selectedApplication) {
      return;
    }

    try {
      promptAction.showToast({ message: '⏳ 正在撤销申请...', duration: 2000 });

      await ReductionService.cancelApplication(this.selectedApplication.id);

      this.showToastSafe('✅ 撤销申请成功');
      await this.loadApplications();
      this.isSheetShow = false;
    } catch (error) {
      console.error('撤销申请失败:', error);
      const errorMsg: string = error instanceof Error ? error.message : String(error);
      this.showToastSafe(`❌ 撤销失败: ${errorMsg}`);
    }
  }


  private async handleAddEmployee() {
    if (this.addEmployeeMode === '批量导入') {
      await this.handleImportAllEmployees();
    } else {
      try {
        const employeeData = new AddEmployeeData();
        employeeData.name = this.newEmployeeName;
        employeeData.idCard = this.newEmployeeIdCard;
        employeeData.hireDate = this.newEmployeeHireDate;
        await UnitService.addEmployee(employeeData);
        this.newEmployeeName = '';
        this.newEmployeeIdCard = '';
        this.newEmployeeHireDate = '';

        await this.loadCompanyInfo();
        await this.loadAllEmployees();
        await this.syncEmployeeCounts();

        this.showToastSafe('职工添加成功');
        this.isSheetShow = false;
      } catch (error) {
        console.error('添加职工失败:', error);
        this.showToastSafe('添加职工失败，请重试');
      }
    }
  }




  private async handleAddDisabledEmployee() {
    try {
      if (this.selectedNonDisabledEmployees.length === 0) {
        this.showToastSafe('请先选择职工');
        return;
      }
      if (!this.newDisabilityLevel || this.newDisabilityLevel.trim().length === 0) {
        this.showToastSafe('请选择残疾等级');
        return;
      }
      const disabledData = new AddDisabledEmployeeData();
      disabledData.employeeIds = this.selectedNonDisabledEmployees;
      disabledData.disabilityType = this.newDisabilityType;
      disabledData.disabilityLevel = this.newDisabilityLevel;
      disabledData.attachment = this.newDisabilityAttachment;
      await UnitService.submitDisabledAuditApplications(disabledData);
      this.selectedNonDisabledEmployees = [];
      await this.loadDisabledEmployees();
      this.showToastSafe('新增残疾职工申请已提交，等待审核');
      this.isSheetShow = false;
    } catch (error) {
      console.error('添加残疾职工失败:', error);
      this.showToastSafe('新增残疾职工失败，请重试');
    }
  }

  private showToastSafe(message: string): void {
    try {
      promptAction.showToast({ message: message });
    } catch (error) {
      console.warn('Toast显示失败:', error);
    }
  }

  private async syncEmployeeCounts() {
    try {
      let totalEmployees = this.totalEmployeesCount;
      let disabledEmployees = this.disabledEmployeesCount;

      try {
        const employeesPage = await UnitService.getEmployees(1, 1);
        totalEmployees = employeesPage.total || 0;
      } catch (error) {
        console.error('同步在职职工人数失败:', error);
      }

      try {
        const disabledList = await UnitService.getDisabledEmployees();
        disabledEmployees = disabledList.length;
      } catch (error) {
        console.error('同步残疾职工人数失败:', error);
      }

      if (this.companyInfo) {
        const current = this.companyInfo;
        this.companyInfo = {
          id: current.id,
          name: current.name,
          creditCode: current.creditCode,
          industry: current.industry,
          establishDate: current.establishDate,
          address: current.address,
          legalPerson: current.legalPerson,
          contactPhone: current.contactPhone,
          totalEmployees: totalEmployees,
          disabledEmployees: disabledEmployees,
          status: current.status
        };
      }
      this.totalEmployeesCount = totalEmployees;
      this.disabledEmployeesCount = disabledEmployees;
    } catch (error) {
      console.error('同步职工人数失败:', error);
    }
  }

  @Builder buildInfoRow(l: string, v: string, c?: string) {
    Row() {
      Text(l).fontColor(ColorConstants.TEXT_SECONDARY).width(100)
      Text(v).fontColor(c || ColorConstants.TEXT_TITLE).layoutWeight(1).textAlign(TextAlign.End)
    }.padding({ top: 8, bottom: 8 })
  }

  @Builder buildDetailRow(l: string, v: string) {
    Row() {
      Text(l).fontColor(ColorConstants.TEXT_SECONDARY).width(100)
      Text(v).fontWeight(FontWeight.Medium).layoutWeight(1).textAlign(TextAlign.End)
    }.padding({ top: 12, bottom: 12 })
  }

  private isCompanyActive(): boolean {
    const status = (this.companyStatusText || '').trim().toUpperCase();
    return status === 'ACTIVE' || status === '1' || status === '正常'.toUpperCase();
  }

  private getApplicationStatusColor(status: string): string {
    if (status === '已通过') {
      return ColorConstants.SUCCESS;
    }
    if (status === '已驳回' || status === '已撤回') {
      return ColorConstants.DANGER;
    }
    return ColorConstants.WARNING;
  }
}

import { ColorConstants } from '../../common/constants/ColorConstants';
import { appViewModel } from '../../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
import { UnitService, AddEmployeeData, AddDisabledEmployeeData, AddEmployeeResponse, DisabledAuditApplication } from '../../services/UnitService';
import { PaymentService, NoticeService } from '../../services/PaymentAndNoticeService';
import { ReductionService, ApplicationSubmitData } from '../../services/ReductionService';
import { AuthService } from '../../services/AuthService';
import { promptAction } from '@kit.ArkUI';

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
  // 单位用户登录后默认进入“残疾职工”页，避免首屏先看到单位信息中尚未刷新完成的统计值
  @State currentTab: string = 'disabled';
  @State isSheetShow: boolean = false;
  @State activeSheet: CustomSheetType = CustomSheetType.NONE;
  @State editUsername: string = '';
  @State editOldPassword: string = '';
  @State editPassword: string = '';
  @State editConfirmPassword: string = '';
  @State editSaving: boolean = false;
  @State editError: string = '';
  @State selectedEmployee: DisabledEmployeeDetail | null = null;
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
      const result = await UnitService.getEmployees(1, 100);
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
    Scroll() {
      Column() {
        if (this.selectedEmployee) {
          this.buildDetailRow('姓名', this.selectedEmployee.name)
          this.buildDetailRow('身份证号', this.selectedEmployee.idCard)
          this.buildDetailRow('残疾类别', this.selectedEmployee.disabilityType)
          this.buildDetailRow('残疾等级', this.selectedEmployee.disabilityLevel)
          this.buildDetailRow('入职时间', this.selectedEmployee.hireDate)
          this.buildDetailRow('审核通过时间', this.selectedEmployee.approvedDate)
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
            .onClick(() => {
              this.showToastSafe('附件上传功能暂未接入');
            })
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
            console.log('选择文件');
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
          TextInput({ placeholder: '请输入附件说明或上传后的文件URL', text: this.newDisabilityAttachment })
            .onChange(v => this.newDisabilityAttachment = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 8 })
          Row() {
            Text(this.newDisabilityAttachment || '点击选择附件')
              .fontSize(14)
              .fontColor(this.newDisabilityAttachment ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
              .layoutWeight(1)
            Button('上传')
              .height(36).fontSize(13)
              .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
              .onClick(() => {
              promptAction.showToast({ message: '附件上传功能暂未接入' });
              })
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
      this.openSheet(CustomSheetType.EMPLOYEE_DETAIL);
    } catch (error) {
      console.error('获取职工详情失败:', error);
    }
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

  private async handleAddEmployee() {
    try {
      if (!this.newEmployeeName.trim()) {
        this.showToastSafe('请输入姓名');
        return;
      }
      if (!this.newEmployeeIdCard.trim()) {
        this.showToastSafe('请输入身份证号');
        return;
      }
      const employeeData = new AddEmployeeData();
      employeeData.name = this.newEmployeeName;
      employeeData.idCard = this.newEmployeeIdCard;
      employeeData.hireDate = this.newEmployeeHireDate;
      await UnitService.addEmployee(employeeData);
      this.newEmployeeName = '';
      this.newEmployeeIdCard = '';
      this.newEmployeeHireDate = '';
      await this.loadCompanyInfo();
      await this.syncEmployeeCounts();
      this.showToastSafe('新增职工成功');
      this.isSheetShow = false;
    } catch (error) {
      console.error('添加职工失败:', error);
      this.showToastSafe(error instanceof Error ? error.message : '新增职工失败');
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
      await this.loadNonDisabledEmployees();
      this.showToastSafe('新增残疾职工申请已提交，等待审核');
      this.isSheetShow = false;
    } catch (error) {
      console.error('添加残疾职工失败:', error);
      this.showToastSafe(error instanceof Error ? error.message : '新增残疾职工失败，请重试');
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

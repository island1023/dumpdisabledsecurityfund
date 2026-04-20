import { ColorConstants } from '../../common/constants/ColorConstants';
import { appViewModel } from '../../viewmodel/AppViewModel';
import { router } from '@kit.ArkUI';
import { UnitService, AddEmployeeData, AddDisabledEmployeeData, AddEmployeeResponse } from '../../services/UnitService';
import { PaymentService, NoticeService } from '../../services/PaymentAndNoticeService';
import { ReductionService, ApplicationSubmitData } from '../../services/ReductionService';

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
interface EmployeeInfo { id: string; name: string; idCard: string; disabilityLevel: string; certificate: string; }
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
  @State currentTab: string = 'info';
  @State isSheetShow: boolean = false;
  @State activeSheet: CustomSheetType = CustomSheetType.NONE;
  @State editUsername: string = '';
  @State editPassword: string = '';
  @State editConfirmPassword: string = '';
  @State selectedEmployee: DisabledEmployeeDetail | null = null;
  @State selectedApplication: ApplicationDetail | null = null;
  @State selectedNotice: NoticeDetail | null = null;
  @State appFormType: string = '减免';
  @State appFormYear: string = '2025';
  @State appFormAmount: string = '';
  @State appFormReason: string = '';
  @State appFormAttachment: string = '';
  @State showAddEmployeeDialog: boolean = false;
  @State addEmployeeMode: string = '手动添加';
  @State newEmployeeName: string = '';
  @State newEmployeeIdCard: string = '';
  @State newEmployeeHireDate: string = '';
  @State newEmployeeId: string = '';
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

  private tabs: TabItem[] = [
    { id: 'info', name: '单位信息', icon: 'building_fill' },
    { id: 'disabled', name: '残疾职工', icon: 'person_2_fill' },
    { id: 'application', name: '减免缓申请', icon: 'doc_text_fill' },
    { id: 'progress', name: '申报进度', icon: 'clock_fill' },
    { id: 'payment', name: '缴费记录', icon: 'creditcard_fill' },
    { id: 'notice', name: '通知单', icon: 'bell_fill' }
  ] as TabItem[];

  aboutToAppear() {
    this.loadCompanyInfo();
    this.loadDisabledEmployees();
    this.loadApplications();
    this.loadPaymentInfo();
    this.loadNotices();
  }

  async loadCompanyInfo() {
    try {
      const info = await UnitService.getCompanyInfo();
      const companyData: CompanyInfo = {
        id: info.id,
        name: info.name,
        creditCode: info.creditCode,
        industry: info.industry,
        establishDate: info.establishDate,
        address: info.address,
        legalPerson: info.legalPerson,
        contactPhone: info.contactPhone,
        totalEmployees: info.totalEmployees,
        disabledEmployees: info.disabledEmployees,
        status: info.status
      };
      this.companyInfo = companyData;
    } catch (error) {
      console.error('加载单位信息失败:', error);
    }
  }

  async loadDisabledEmployees() {
    try {
      const employees = await UnitService.getDisabledEmployees();
      const mappedEmployees: EmployeeInfo[] = [];
      for (let i = 0; i < employees.length; i++) {
        const e = employees[i];
        mappedEmployees.push({
          id: e.id,
          name: e.name,
          idCard: e.idCard,
          disabilityLevel: e.disabilityLevel || '三级',
          certificate: '有效'
        });
      }
      this.disabledEmployees = mappedEmployees;
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
            else if (this.currentTab === 'progress') { this.buildProgress() }
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
    Column() {
      if (this.activeSheet === CustomSheetType.PROFILE) {
        this.buildProfileSheet()
      } else if (this.activeSheet === CustomSheetType.EDIT_PROFILE) {
        this.buildEditProfileDialog()
      } else if (this.activeSheet === CustomSheetType.ALL_EMPLOYEES) {
        this.buildAllEmployeesDialog()
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
      } else if (this.activeSheet === CustomSheetType.ADD_DISABLED) {
        this.buildAddDisabledDialog()
      }
    }
    .padding({ top: 20 })
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
        .onClick(() => { this.currentTab = tab.id; })
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
            Text(this.companyInfo?.name || '加载中...').fontSize(18).fontWeight(FontWeight.Bold)
            Text(`统一社会信用代码：${this.companyInfo?.creditCode || '-'}`).fontSize(12).fontColor(ColorConstants.TEXT_SECONDARY).margin({ top: 4 })
          }.alignItems(HorizontalAlign.Start).margin({ left: 12 }).layoutWeight(1)
        }
        Divider().color(ColorConstants.BORDER).margin({ top: 16, bottom: 16 })
        this.buildInfoRow('所属行业', this.companyInfo?.industry || '-')
        this.buildInfoRow('成立日期', this.companyInfo?.establishDate || '-')
        this.buildInfoRow('注册地址', this.companyInfo?.address || '-')
        this.buildInfoRow('法定代表人', this.companyInfo?.legalPerson || '-')
        this.buildInfoRow('联系电话', this.companyInfo?.contactPhone || '-')
        this.buildInfoRow('在职职工', `${this.companyInfo?.totalEmployees || 0}人`)
        this.buildInfoRow('残疾职工', `${this.companyInfo?.disabledEmployees || 0}人`)
        this.buildInfoRow('单位状态', this.companyInfo?.status === 'ACTIVE' ? '正常' : '异常', ColorConstants.SUCCESS)

        Row() {
          Button('新增职工')
            .layoutWeight(1).height(44).margin({ top: 16, right: 8 })
            .backgroundColor(ColorConstants.PRIMARY).fontColor(ColorConstants.BG_CARD)
            .onClick(() => this.openSheet(CustomSheetType.ADD_EMPLOYEE))
          Button('查看全体职工')
            .layoutWeight(1).height(44).margin({ top: 16, left: 8 })
            .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
            .onClick(() => {
              this.loadAllEmployees();
              this.openSheet(CustomSheetType.ALL_EMPLOYEES);
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
            }.alignItems(HorizontalAlign.Start).layoutWeight(1)

            Button('详情').height(32).fontSize(12)
              .onClick(() => this.viewEmployeeDetail(employee))
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
              Text(`${record.year}${record.type}申请`).fontWeight(FontWeight.Medium).layoutWeight(1)
              Text(record.status).fontColor(ColorConstants.SUCCESS)
            }
            Button('查看详情').width('100%').height(36).margin({ top: 12 })
              .onClick(() => {
                this.viewApplicationDetail(record);
              })
          }
          .padding(16).backgroundColor(ColorConstants.BG_CARD).borderRadius(12).margin({ bottom: 12 })
        })
      }
    }
  }

  @Builder
  buildProgress() {
    Column() {
      Text('当前申报进度').fontSize(16).fontWeight(FontWeight.Bold).margin({ bottom: 16 })

      Column() {
        this.buildProgressStep('填写申报表', 'completed', '2025-04-10 09:30')
        this.buildProgressStep('上传证明材料', 'completed', '2025-04-10 10:15')
        this.buildProgressStep('提交审核', 'current', '2025-04-10 10:20')
        this.buildProgressStep('区级审核', 'pending', '')
        this.buildProgressStep('市级复核', 'pending', '')
        this.buildProgressStep('审核完成', 'pending', '')
      }
      .width('100%').padding(16)
      .backgroundColor(ColorConstants.BG_CARD).borderRadius(12)
      .border({ width: 1, color: ColorConstants.BORDER })

      Row() {
        SymbolGlyph($r('sys.symbol.info_circle')).fontSize(18).fontColor([ColorConstants.WARNING])
        Text('当前正在等待区级审核，预计3-5个工作日完成')
          .fontSize(13).fontColor(ColorConstants.TEXT_SECONDARY)
          .margin({ left: 8 }).layoutWeight(1)
      }
      .width('100%').padding(12).margin({ top: 16 })
      .backgroundColor('rgba(255, 193, 7, 0.1)').borderRadius(8)
    }
    .width('100%')
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
            Text(notice.title).layoutWeight(1)
            SymbolGlyph($r('sys.symbol.chevron_right'))
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
      TextInput({ placeholder: '用户名', text: this.editUsername }).margin({ bottom: 12 })
        .onChange(v => this.editUsername = v)
      TextInput({ placeholder: '新密码' }).type(InputType.Password).margin({ bottom: 12 })
        .onChange(v => this.editPassword = v)
      Button('保存修改').width('100%').onClick(() => this.handleSaveProfile())
    }.padding(20)
  }

  @Builder
  buildAllEmployeesDialog() {
    Scroll() {
      Column() {
        if (this.allEmployees.length === 0) {
          Text('暂无职工数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .padding(20)
        } else {
          ForEach(this.allEmployees, (emp: AllEmployee, index: number) => {
            Row() {
              Column() {
                Text(emp.name)
                  .fontSize(15)
                  .fontWeight(FontWeight.Medium)
                  .fontColor(ColorConstants.TEXT_TITLE)

                Text(`工号：${emp.id}`)
                  .fontSize(12)
                  .fontColor(ColorConstants.TEXT_SECONDARY)
                  .margin({ top: 4 })

                Text(`入职时间：${emp.hireDate}`)
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
            .margin({ bottom: 8 })
          })
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
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
          Button('减免')
            .layoutWeight(1).height(44)
            .fontColor(this.appFormType === '减免' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.appFormType === '减免' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ right: 4 })
            .onClick(() => { this.appFormType = '减免'; })
          Button('缓缴')
            .layoutWeight(1).height(44)
            .fontColor(this.appFormType === '缓缴' ? ColorConstants.BG_CARD : ColorConstants.PRIMARY)
            .backgroundColor(this.appFormType === '缓缴' ? ColorConstants.PRIMARY : 'rgba(199, 28, 34, 0.1)')
            .borderRadius(8).margin({ left: 4 })
            .onClick(() => { this.appFormType = '缓缴'; })
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
              this.appFormAttachment = '证明材料.pdf';
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
            .onClick(() => this.submitApplication())
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
            Text(this.selectedNotice.type)
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

          Text(this.selectedNotice.content)
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
          Text('工号').fontSize(14).fontColor(ColorConstants.TEXT_SECONDARY).margin({ bottom: 8 })
          TextInput({ placeholder: '请输入工号', text: this.newEmployeeId })
            .onChange(v => this.newEmployeeId = v)
            .width('100%').height(44).fontSize(14)
            .backgroundColor(ColorConstants.BG_PAGE).borderRadius(8)
            .padding({ left: 12, right: 12 }).margin({ bottom: 16 })

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
                    this.selectedNonDisabledEmployees.push(emp.id);
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
          Text(this.newDisabilityAttachment || '点击选择附件')
            .fontSize(14)
            .fontColor(this.newDisabilityAttachment ? ColorConstants.TEXT_TITLE : ColorConstants.TEXT_SECONDARY)
            .layoutWeight(1)
          Button('上传')
            .height(36).fontSize(13)
            .backgroundColor('rgba(199, 28, 34, 0.1)').fontColor(ColorConstants.PRIMARY)
            .onClick(() => {
              this.newDisabilityAttachment = '残疾证明.pdf';
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
      .padding({ left: 20, right: 20 })
    }
    .width('100%')
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
        hireDate: detail.hireDate,
        approvedDate: detail.approvedDate
      };
      this.openSheet(CustomSheetType.EMPLOYEE_DETAIL);
    } catch (error) {
      console.error('获取职工详情失败:', error);
    }
  }

  private viewApplicationDetail(record: ApplicationRecord) {
    let rawAmount = record.amount.replace('￥', '').replace('¥', '').replace(',', '');
    this.selectedApplication = {
      id: record.id,
      type: record.type,
      year: record.year,
      amount: rawAmount,
      reason: '因公司经营困难，申请减免残疾人就业保障金',
      attachment: '证明材料.pdf',
      status: record.status,
      submitDate: record.date
    };
    this.openSheet(CustomSheetType.APP_DETAIL);
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
    console.log('保存用户:', this.editUsername);
    this.isSheetShow = false;
  }

  private handleLogout() {
    this.isSheetShow = false;
    appViewModel.logout();
    router.replaceUrl({ url: 'pages/LoginPage' });
  }

  private async submitApplication() {
    try {
      const appData: ApplicationSubmitData = {
        type: this.appFormType,
        year: this.appFormYear,
        amount: this.appFormAmount,
        reason: this.appFormReason,
        attachment: this.appFormAttachment
      };
      await ReductionService.submitApplication(appData);
      this.loadApplications();
      this.isSheetShow = false;
    } catch (error) {
      console.error('提交申请失败:', error);
    }
  }

  private async handleAddEmployee() {
    try {
      const employeeData: AddEmployeeData = {
        name: this.newEmployeeName,
        idCard: this.newEmployeeIdCard,
        hireDate: this.newEmployeeHireDate
      };
      await UnitService.addEmployee(employeeData);
      this.isSheetShow = false;
    } catch (error) {
      console.error('添加职工失败:', error);
    }
  }

  private async handleAddDisabledEmployee() {
    try {
      const disabledData: AddDisabledEmployeeData = {
        employeeIds: this.selectedNonDisabledEmployees,
        disabilityType: this.newDisabilityType,
        disabilityLevel: this.newDisabilityLevel,
        attachment: this.newDisabilityAttachment
      };
      await UnitService.addDisabledEmployees(disabledData);
      this.loadDisabledEmployees();
      this.isSheetShow = false;
    } catch (error) {
      console.error('添加残疾职工失败:', error);
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

  @Builder
  buildProgressStep(title: string, status: string, time: string) {
    Row() {
      Stack() {
        Circle()
          .width(24)
          .height(24)
          .fill(status === 'completed' ? ColorConstants.SUCCESS :
                status === 'current' ? ColorConstants.PRIMARY : ColorConstants.BORDER)

        if (status === 'completed') {
          SymbolGlyph($r('sys.symbol.checkmark'))
            .fontSize(14)
            .fontColor([ColorConstants.BG_CARD])
        } else if (status === 'current') {
          Circle()
            .width(10)
            .height(10)
            .fill(ColorConstants.BG_CARD)
        }
      }
      .width(24)
      .height(24)

      if (title !== '审核完成') {
        Column()
          .width(2)
          .height(30)
          .backgroundColor(status === 'completed' ? ColorConstants.SUCCESS : ColorConstants.BORDER)
          .margin({ left: 11 })
      }

      Column() {
        Text(title)
          .fontSize(14)
          .fontWeight(status === 'current' ? FontWeight.Bold : FontWeight.Normal)
          .fontColor(status === 'pending' ? ColorConstants.TEXT_SECONDARY : ColorConstants.TEXT_TITLE)

        if (time) {
          Text(time)
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ top: 2 })
        }
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
      .layoutWeight(1)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }
}

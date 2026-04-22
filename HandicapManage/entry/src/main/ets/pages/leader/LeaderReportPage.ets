import { ColorConstants } from '../../common/constants/ColorConstants';
import { LeaderService } from '../../services/LeaderService';
import { promptAction } from '@kit.ArkUI';
import { appViewModel } from '../../viewmodel/AppViewModel';

// 报表类型
enum ReportType {
  UNIT_INFO = '单位信息统计表',
  UNPAID_UNIT = '未缴款单位统计',
  PAYMENT_STAT = '缴纳保障金统计',
  RELIEF_STAT = '减免缓缴保障金统计'
}

// 报表配置
interface ReportConfig {
  type: ReportType;
  year: number;
  month: number;
}

// 单位信息统计数据
interface UnitStatItem {
  district: string;
  unitCount: number;
  totalEmployees: number;
  disabledEmployees: number;
}

// 未缴款单位统计
interface UnpaidUnitItem {
  companyName: string;
  district: string;
  year: string;
  payableAmount: number;
  unpaidMonths: number;
}

// 缴纳统计
interface PaymentStatItem {
  district: string;
  totalPayable: number;
  totalPaid: number;
  paymentRate: number;
}

// 减免缓统计
interface ReliefStatItem {
  type: string;
  unitCount: number;
  totalAmount: number;
  approvedCount: number;
}

// 饼图数据项接口
interface PieChartItem {
  label: string;
  value: number;
  color: string;
}

// 弹窗类型
enum ReportSheetType {
  NONE,
  CONFIG,
  DETAIL
}

@Component
export struct LeaderReportPage {
  @State isSheetShow: boolean = false;
  @State activeSheet: ReportSheetType = ReportSheetType.NONE;
  @State selectedReportType: ReportType = ReportType.UNIT_INFO;
  @State selectedYear: number = new Date().getFullYear();
  @State selectedMonth: number = new Date().getMonth() + 1;
  @State showConfig: boolean = false;

  @State unitStats: UnitStatItem[] = [];
  @State unpaidUnits: UnpaidUnitItem[] = [];
  @State paymentStats: PaymentStatItem[] = [];
  @State reliefStats: ReliefStatItem[] = [];
  @State reportLoading: boolean = false;
  @State maxUnitCountBar: number = 1;
  @State maxPaymentPayableBar: number = 1;
  @State localDistrictName: string = '';

  aboutToAppear(): void {
    this.localDistrictName = this.resolveLocalDistrictName();
    this.loadReportData();
  }

  private resolveLocalDistrictName(): string {
    const user = appViewModel.currentUser;
    if (!user) {
      return '';
    }
    const name = user.districtName ? user.districtName.trim() : '';
    if (name.length > 0 && name !== '未知区域') {
      return name;
    }
    const byCode: Record<string, string> = {
      '1': '锦江区',
      '2': '青羊区',
      '3': '金牛区',
      '4': '武侯区',
      '5': '成华区',
      '6': '龙泉驿区',
      '7': '青白江区',
      '8': '新都区',
      '9': '温江区',
      '10': '双流区',
      '11': '郫都区',
      '12': '新津区',
      '13': '金堂县'
    };
    return byCode[user.districtCode] || '';
  }

  private isLocalDistrict(district: string): boolean {
    if (!this.localDistrictName || this.localDistrictName.trim().length === 0) {
      return false;
    }
    const lhs = district ? district.trim() : '';
    const rhs = this.localDistrictName.trim();
    return lhs === rhs;
  }

  private localUnitStat(): UnitStatItem | null {
    for (let i = 0; i < this.unitStats.length; i++) {
      if (this.isLocalDistrict(this.unitStats[i].district)) {
        return this.unitStats[i];
      }
    }
    return null;
  }

  private localPaymentStat(): PaymentStatItem | null {
    for (let i = 0; i < this.paymentStats.length; i++) {
      if (this.isLocalDistrict(this.paymentStats[i].district)) {
        return this.paymentStats[i];
      }
    }
    return null;
  }

  private reportTypeCode(): string {
    switch (this.selectedReportType) {
      case ReportType.UNIT_INFO:
        return 'UNIT_INFO';
      case ReportType.UNPAID_UNIT:
        return 'UNPAID_UNIT';
      case ReportType.PAYMENT_STAT:
        return 'PAYMENT_STAT';
      case ReportType.RELIEF_STAT:
        return 'RELIEF_STAT';
      default:
        return 'UNIT_INFO';
    }
  }

  private readRowString(row: Record<string, Object>, key: string): string {
    const v = row[key];
    if (typeof v === 'string') {
      return v;
    }
    if (typeof v === 'number') {
      return `${v}`;
    }
    return '';
  }

  private readRowNumber(row: Record<string, Object>, key: string): number {
    const v = row[key];
    if (typeof v === 'number') {
      return v;
    }
    if (typeof v === 'string') {
      const n = Number(v);
      return Number.isNaN(n) ? 0 : n;
    }
    return 0;
  }

  async loadReportData(): Promise<void> {
    this.reportLoading = true;
    try {
      const bundle = await LeaderService.getReport(this.reportTypeCode(), this.selectedYear, this.selectedMonth);
      const rows = bundle.rows;
      if (this.selectedReportType === ReportType.UNIT_INFO) {
        const next: UnitStatItem[] = [];
        let maxU = 1;
        for (let i = 0; i < rows.length; i++) {
          const r = rows[i];
          const uc = this.readRowNumber(r, 'unitCount');
          if (uc > maxU) {
            maxU = uc;
          }
          next.push({
            district: this.readRowString(r, 'district'),
            unitCount: uc,
            totalEmployees: this.readRowNumber(r, 'totalEmployees'),
            disabledEmployees: this.readRowNumber(r, 'disabledEmployees')
          });
        }
        this.unitStats = next;
        this.maxUnitCountBar = maxU;
      } else if (this.selectedReportType === ReportType.UNPAID_UNIT) {
        const next: UnpaidUnitItem[] = [];
        for (let i = 0; i < rows.length; i++) {
          const r = rows[i];
          next.push({
            companyName: this.readRowString(r, 'companyName'),
            district: this.readRowString(r, 'district'),
            year: this.readRowString(r, 'year'),
            payableAmount: this.readRowNumber(r, 'payableAmount'),
            unpaidMonths: this.readRowNumber(r, 'unpaidMonths')
          });
        }
        this.unpaidUnits = next;
      } else if (this.selectedReportType === ReportType.PAYMENT_STAT) {
        const next: PaymentStatItem[] = [];
        let maxP = 1;
        for (let i = 0; i < rows.length; i++) {
          const r = rows[i];
          const tp = this.readRowNumber(r, 'totalPayable');
          if (tp > maxP) {
            maxP = tp;
          }
          next.push({
            district: this.readRowString(r, 'district'),
            totalPayable: tp,
            totalPaid: this.readRowNumber(r, 'totalPaid'),
            paymentRate: this.readRowNumber(r, 'paymentRate')
          });
        }
        this.paymentStats = next;
        this.maxPaymentPayableBar = maxP > 0 ? maxP : 1;
      } else if (this.selectedReportType === ReportType.RELIEF_STAT) {
        const next: ReliefStatItem[] = [];
        for (let i = 0; i < rows.length; i++) {
          const r = rows[i];
          next.push({
            type: this.readRowString(r, 'type'),
            unitCount: this.readRowNumber(r, 'unitCount'),
            totalAmount: this.readRowNumber(r, 'totalAmount'),
            approvedCount: this.readRowNumber(r, 'approvedCount')
          });
        }
        this.reliefStats = next;
      }
    } catch (e) {
      promptAction.showToast({ message: (e as Error).message || '加载报表失败' });
      this.unitStats = [];
      this.unpaidUnits = [];
      this.paymentStats = [];
      this.reliefStats = [];
    } finally {
      this.reportLoading = false;
    }
  }

  // 打开配置弹窗
  private openConfig() {
    this.activeSheet = ReportSheetType.CONFIG;
    this.isSheetShow = true;
  }

  // 生成报表
  private handleGenerateReport(): void {
    this.isSheetShow = false;
    void this.loadReportData();
  }

  build() {
    Column() {
      // 报表配置区域
      Row() {
        Column() {
          Text('报表类型')
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ bottom: 8 })

          Text(this.selectedReportType)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)

        Column() {
          Text('统计时间')
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ bottom: 8 })

          Text(`${this.selectedYear}年${this.selectedMonth}月`)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Medium)
        }
        .layoutWeight(1)

        Button('配置')
          .width(80)
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .margin({ left: 12 })
          .onClick(() => {
            this.openConfig();
          })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorConstants.BG_CARD)
      .borderRadius(12)
      .margin({ bottom: 16 })

      if (this.reportLoading) {
        Text('加载报表数据…')
          .fontSize(14)
          .fontColor(ColorConstants.TEXT_SECONDARY)
          .width('100%')
          .margin({ bottom: 8 })
      }

      if (!this.reportLoading && this.localDistrictName.trim().length > 0 && this.selectedReportType === ReportType.UNIT_INFO && this.localUnitStat() !== null) {
        this.buildLocalUnitSummaryCard(this.localUnitStat()!)
      }

      if (!this.reportLoading && this.localDistrictName.trim().length > 0 && this.selectedReportType === ReportType.PAYMENT_STAT && this.localPaymentStat() !== null) {
        this.buildLocalPaymentSummaryCard(this.localPaymentStat()!)
      }

      // 报表内容 - 可滚动
      Scroll() {
        Column() {
          if (this.selectedReportType === ReportType.UNIT_INFO) {
            this.buildUnitInfoReport()
          } else if (this.selectedReportType === ReportType.UNPAID_UNIT) {
            this.buildUnpaidUnitReport()
          } else if (this.selectedReportType === ReportType.PAYMENT_STAT) {
            this.buildPaymentStatReport()
          } else if (this.selectedReportType === ReportType.RELIEF_STAT) {
            this.buildReliefStatReport()
          }
        }
        .width('100%')
        .padding({ bottom: 20 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .edgeEffect(EdgeEffect.Spring)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .bindSheet($$this.isSheetShow, this.sheetBuilder(), {
      detents: [SheetSize.MEDIUM],
      preferType: SheetType.BOTTOM,
      showClose: true,
      title: { title: '报表配置' },
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = ReportSheetType.NONE;
      }
    })
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === ReportSheetType.CONFIG) {
        this.buildConfigDialog()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildConfigDialog() {
    Column() {
      Text('选择报表类型')
        .fontSize(16)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        ForEach(Object.values(ReportType), (type: ReportType) => {
          Row() {
            Text(type)
              .fontSize(14)
              .fontColor(this.selectedReportType === type ? ColorConstants.PRIMARY : ColorConstants.TEXT_TITLE)
              .fontWeight(this.selectedReportType === type ? FontWeight.Medium : FontWeight.Normal)
              .layoutWeight(1)

            if (this.selectedReportType === type) {
              Text('✓')
                .fontSize(18)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Bold)
            }
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.selectedReportType === type ? 'rgba(199, 28, 34, 0.05)' : ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 8 })
          .onClick(() => {
            this.selectedReportType = type;
          })
        })
      }
      .width('100%')
      .margin({ bottom: 24 })

      Button('生成报表')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontColor('#FFFFFF')
        .backgroundColor(ColorConstants.PRIMARY)
        .borderRadius(8)
        .onClick(() => {
          this.handleGenerateReport();
        })
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }

  // 单位信息统计报表
  @Builder
  buildUnitInfoReport() {
    Column() {
      // 图表标题
      Text('各区单位信息统计')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      // 柱状图
      Column() {
        ForEach(this.unitStats, (item: UnitStatItem) => {
          Column() {
            Row() {
              Text(item.district)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_TITLE)
                .width(80)

              Row() {
                Row()
                  .width(`${(item.unitCount / (this.maxUnitCountBar > 0 ? this.maxUnitCountBar : 1)) * 100}%`)
                  .height(20)
                  .backgroundColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.PRIMARY)
                  .borderRadius(4)
              }
              .layoutWeight(1)
              .height(20)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(4)

              Text(this.isLocalDistrict(item.district) ? `${item.unitCount}家（本区）` : `${item.unitCount}家`)
                .fontSize(13)
                .fontColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Medium)
                .width(88)
                .textAlign(TextAlign.End)
            }
            .width('100%')
          }
          .width('100%')
          .margin({ bottom: 12 })
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorConstants.BG_CARD)
      .borderRadius(12)
      .margin({ bottom: 20 })

      // 统计表格
      Text('详细数据')
        .fontSize(16)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        // 表头
        Row() {
          Text('区域')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('单位数')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('在职职工')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('残疾职工')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 8 })

        // 数据行
        ForEach(this.unitStats, (item: UnitStatItem) => {
          Row() {
            Text(item.district)
              .fontSize(13)
              .fontColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.TEXT_TITLE)
              .fontWeight(this.isLocalDistrict(item.district) ? FontWeight.Medium : FontWeight.Normal)
              .layoutWeight(1)

            Text(`${item.unitCount}`)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`${item.totalEmployees}`)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`${item.disabledEmployees}`)
              .fontSize(13)
              .fontColor(ColorConstants.PRIMARY)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.isLocalDistrict(item.district) ? 'rgba(245, 158, 11, 0.10)' : ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 4 })
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 未缴款单位统计报表
  @Builder
  buildUnpaidUnitReport() {
    Column() {
      // 明细表
      Text('未缴款单位明细')
        .fontSize(16)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          Text('单位名称')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(2)

          Text('区域')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('应缴金额')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('未缴月数')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 8 })

        ForEach(this.unpaidUnits, (item: UnpaidUnitItem) => {
          Row() {
            Text(item.companyName)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(2)

            Text(item.district)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`¥${(item.payableAmount / 10000).toFixed(1)}万`)
              .fontSize(13)
              .fontColor(ColorConstants.PRIMARY)
              .layoutWeight(1)

            Text(`${item.unpaidMonths}个月`)
              .fontSize(13)
              .fontColor(ColorConstants.DANGER)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 4 })
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 缴纳保障金统计报表
  @Builder
  buildPaymentStatReport() {
    Column() {
      Text('各区缴纳保障金统计')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      // 柱状图(优化布局,避免百分比重叠)
      Column({ space: 12 }) {
        ForEach(this.paymentStats, (item: PaymentStatItem) => {
          Row() {
            Text(item.district)
              .fontSize(13)
              .fontColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.TEXT_TITLE)
              .fontWeight(this.isLocalDistrict(item.district) ? FontWeight.Medium : FontWeight.Normal)
              .width(70)

            Column({ space: 4 }) {
              // 应缴进度条
              Row() {
                Row()
                  .width(`${(item.totalPayable / this.maxPaymentPayableBar) * 100}%`)
                  .height(8)
                  .backgroundColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.PRIMARY)
                  .borderRadius(4)
              }
              .width('100%')
              .height(8)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(4)

              // 实缴进度条
              Row() {
                Row()
                  .width(`${(item.totalPaid / this.maxPaymentPayableBar) * 100}%`)
                  .height(8)
                  .backgroundColor(ColorConstants.SUCCESS)
                  .borderRadius(4)
              }
              .width('100%')
              .height(8)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(4)
            }
            .layoutWeight(1)

            Text(`${item.paymentRate}%`)
              .fontSize(13)
              .fontColor(item.paymentRate >= 95 ? ColorConstants.SUCCESS : ColorConstants.WARNING)
              .fontWeight(FontWeight.Medium)
              .width(55)
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.isLocalDistrict(item.district) ? 'rgba(245, 158, 11, 0.10)' : ColorConstants.BG_PAGE)
          .borderRadius(8)
        })
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorConstants.BG_CARD)
      .borderRadius(12)
      .margin({ bottom: 20 })

      // 图例
      Row() {
        Row() {
          Rect()
            .width(12)
            .height(12)
            .fill(ColorConstants.PRIMARY)
            .borderRadius(2)
            .margin({ right: 8 })

          Text('应缴金额')
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .margin({ right: 24 })

        Row() {
          Rect()
            .width(12)
            .height(12)
            .fill(ColorConstants.SUCCESS)
            .borderRadius(2)
            .margin({ right: 8 })

          Text('实缴金额')
            .fontSize(12)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 20 })

      // 详细数据表格
      Text('详细数据')
        .fontSize(16)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          Text('区域')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('应缴(万)')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('实缴(万)')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('缴纳率')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 8 })

        ForEach(this.paymentStats, (item: PaymentStatItem) => {
          Row() {
            Text(item.district)
              .fontSize(13)
              .fontColor(this.isLocalDistrict(item.district) ? ColorConstants.WARNING : ColorConstants.TEXT_TITLE)
              .fontWeight(this.isLocalDistrict(item.district) ? FontWeight.Medium : FontWeight.Normal)
              .layoutWeight(1)

            Text(`${(item.totalPayable / 10000).toFixed(1)}`)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`${(item.totalPaid / 10000).toFixed(1)}`)
              .fontSize(13)
              .fontColor(ColorConstants.SUCCESS)
              .layoutWeight(1)

            Text(`${item.paymentRate}%`)
              .fontSize(13)
              .fontColor(item.paymentRate >= 95 ? ColorConstants.SUCCESS : ColorConstants.WARNING)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(this.isLocalDistrict(item.district) ? 'rgba(245, 158, 11, 0.10)' : ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 4 })
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  private buildLocalUnitSummaryCard(item: UnitStatItem) {
    Row() {
      Text(`本区（${item.district}）单位概览：单位 ${item.unitCount} 家，在职 ${item.totalEmployees} 人，残疾职工 ${item.disabledEmployees} 人`)
        .fontSize(13)
        .fontColor(ColorConstants.WARNING)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(245, 158, 11, 0.10)')
    .border({ width: 1, color: 'rgba(245, 158, 11, 0.35)' })
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  @Builder
  private buildLocalPaymentSummaryCard(item: PaymentStatItem) {
    Row() {
      Text(`本区（${item.district}）缴纳概览：应缴 ${(item.totalPayable / 10000).toFixed(1)} 万，实缴 ${(item.totalPaid / 10000).toFixed(1)} 万，缴纳率 ${item.paymentRate.toFixed(1)}%`)
        .fontSize(13)
        .fontColor(ColorConstants.WARNING)
        .fontWeight(FontWeight.Medium)
        .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(245, 158, 11, 0.10)')
    .border({ width: 1, color: 'rgba(245, 158, 11, 0.35)' })
    .borderRadius(8)
    .margin({ bottom: 12 })
  }

  // 减免缓缴保障金统计报表
  @Builder
  buildReliefStatReport() {
    Column() {
      // 详细数据表格
      Text('详细数据')
        .fontSize(16)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 12 })

      Column() {
        Row() {
          Text('类型')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('单位数')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('总金额(万)')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          Text('已通过')
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)
        }
        .width('100%')
        .padding(12)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 8 })

        ForEach(this.reliefStats, (item: ReliefStatItem) => {
          Row() {
            Text(item.type)
              .fontSize(13)
              .fontColor(ColorConstants.PRIMARY)
              .layoutWeight(1)

            Text(`${item.unitCount}`)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`${(item.totalAmount / 10000).toFixed(1)}`)
              .fontSize(13)
              .fontColor(ColorConstants.TEXT_TITLE)
              .layoutWeight(1)

            Text(`${item.approvedCount}`)
              .fontSize(13)
              .fontColor(ColorConstants.SUCCESS)
              .layoutWeight(1)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 4 })
        })
      }
      .width('100%')
    }
    .width('100%')
  }

  // 辅助方法
  private getBarWidth(value: number, maxValue: number): number {
    const max = maxValue > 0 ? maxValue : 1;
    return Math.max(20, (value / max) * 200);
  }

  private getColorByIndex(index: number): string {
    const colors = [
      ColorConstants.PRIMARY,
      ColorConstants.SUCCESS,
      ColorConstants.WARNING,
      '#4A90E2',
      '#9B59B6'
    ];
    return colors[index % colors.length];
  }

  // 获取饼图数据
  private getUnpaidPieData(): PieChartItem[] {
    const result: PieChartItem[] = [];
    for (let i = 0; i < this.unpaidUnits.length; i++) {
      const item = this.unpaidUnits[i];
      const pieItem: PieChartItem = {
        label: item.companyName,
        value: item.payableAmount,
        color: this.getColorByIndex(i)
      };
      result.push(pieItem);
    }
    return result;
  }

  private getReliefPieData(): PieChartItem[] {
    const result: PieChartItem[] = [];
    for (let i = 0; i < this.reliefStats.length; i++) {
      const item = this.reliefStats[i];
      const pieItem: PieChartItem = {
        label: item.type,
        value: item.totalAmount,
        color: this.getColorByIndex(i)
      };
      result.push(pieItem);
    }
    return result;
  }

  // 数据卡片列表展示
  @Builder
  buildPieChart(data: PieChartItem[], width: number, height: number) {
    Column({ space: 8 }) {
      ForEach(data, (item: PieChartItem, index: number) => {
        Row() {
          // 颜色标识
          Circle()
            .width(10)
            .height(10)
            .fill(item.color)
          
          // 标签
          Text(item.label)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_BODY)
            .margin({ left: 12, right: 12 })
          
          // 数值
          Text(this.formatNumber(item.value))
            .fontSize(15)
            .fontColor(ColorConstants.TEXT_TITLE)
            .fontWeight(FontWeight.Bold)
          
          // 百分比
          Text(`${this.calculatePercentage(item, data)}%`)
            .fontSize(13)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .margin({ left: 8 })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12, left: 16, right: 16 })
        .backgroundColor(ColorConstants.BG_CARD)
        .borderRadius(8)
      })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#F5F5F5')
    .borderRadius(12)
  }

  // 计算百分比
  private calculatePercentage(item: PieChartItem, data: PieChartItem[]): string {
    const total = this.getTotalValue(data);
    if (total === 0) {
      return '0.0';
    }
    return ((item.value / total) * 100).toFixed(1);
  }

  // 格式化数字
  private formatNumber(num: number): string {
    if (num >= 10000) {
      return `${(num / 10000).toFixed(1)}万`;
    }
    return num.toString();
  }

  private getTotalValue(data: PieChartItem[]): number {
    return data.reduce((sum, item) => sum + item.value, 0);
  }
}

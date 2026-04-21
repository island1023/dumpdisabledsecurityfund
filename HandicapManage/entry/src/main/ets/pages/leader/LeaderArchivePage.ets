import { ColorConstants } from '../../common/constants/ColorConstants';

// 单位基本信息接口
interface UnitBasicInfo {
  id: string;
  companyName: string;
  creditCode: string; // 统一社会信用代码
  legalPerson: string; // 法定代表人
  registerAddress: string; // 注册地
  establishDate: string; // 成立日期
  phone: string; // 联系电话
  employeeCount: number; // 在职职工数
  disabledCount: number; // 残疾职工数
  collectionYear: string; // 征收年度
  district: string; // 所属区
}

// 历年缴纳记录
interface PaymentRecord {
  year: string;
  payableAmount: number; // 应缴金额
  paidAmount: number; // 实缴金额
  status: string; // '已缴' | '未缴' | '部分缴纳'
  payDate?: string; // 缴纳日期
}

// 减免缓状态
interface ReliefStatus {
  type: string; // '减免' | '缓缴' | '无'
  reason: string; // 原因
  startDate: string; // 开始日期
  endDate: string; // 结束日期
  amount: number; // 减免/缓缴金额
  status: string; // '审批中' | '已通过' | '已拒绝'
}

// 弹窗类型枚举
enum ArchiveSheetType {
  NONE,
  PAYMENT_RECORDS,
  RELIEF_STATUS
}

interface DistrictOption {
  code: string;
  name: string;
}

@Component
export struct LeaderArchivePage {
  @State searchKeyword: string = '';
  @State selectedDistrict: string = 'all';
  @State isSheetShow: boolean = false;
  @State activeSheet: ArchiveSheetType = ArchiveSheetType.NONE;
  @State selectedUnit: UnitBasicInfo | null = null;
  @State showDistrictDialog: boolean = false;
  private districtList: DistrictOption[] = [
    { code: 'all', name: '全市' },
    { code: '510104', name: '锦江区' },
    { code: '510105', name: '青羊区' },
    { code: '510106', name: '金牛区' },
    { code: '510107', name: '武侯区' },
    { code: '510108', name: '成华区' },
    { code: '510112', name: '龙泉驿区' },
    { code: '510113', name: '青白江区' },
    { code: '510114', name: '新都区' },
    { code: '510115', name: '温江区' },
    { code: '510116', name: '双流区' },
    { code: '510117', name: '郫都区' }
  ];

  // 模拟单位数据
  @State unitList: UnitBasicInfo[] = [
    {
      id: '1',
      companyName: '成都科技发展有限公司',
      creditCode: '91440101MA5ABCD123',
      legalPerson: '张三',
      registerAddress: '成都市锦江区春熙路XX号',
      establishDate: '2018-05-15',
      phone: '020-12345678',
      employeeCount: 150,
      disabledCount: 3,
      collectionYear: '2025年',
      district: '锦江区'
    },
    {
      id: '2',
      companyName: '珠江商贸集团',
      creditCode: '91440101MA5EFGH456',
      legalPerson: '李四',
      registerAddress: '成都市青羊区顺城大街XX号',
      establishDate: '2015-03-20',
      phone: '020-87654321',
      employeeCount: 200,
      disabledCount: 5,
      collectionYear: '2025年',
      district: '青羊区'
    },
    {
      id: '3',
      companyName: '白云制造有限公司',
      creditCode: '91440101MA5IJKL789',
      legalPerson: '王五',
      registerAddress: '成都市金牛区一环路XX号',
      establishDate: '2010-08-10',
      phone: '020-11223344',
      employeeCount: 300,
      disabledCount: 7,
      collectionYear: '2025年',
      district: '金牛区'
    },
    {
      id: '4',
      companyName: '天河建设集团',
      creditCode: '91440101MA5MNOP012',
      legalPerson: '赵六',
      registerAddress: '成都市锦江区东大街XX号',
      establishDate: '2008-12-01',
      phone: '020-55667788',
      employeeCount: 400,
      disabledCount: 6,
      collectionYear: '2025年',
      district: '锦江区'
    },
    {
      id: '5',
      companyName: '黄埔实业有限公司',
      creditCode: '91440101MA5QRST345',
      legalPerson: '孙七',
      registerAddress: '成都市武侯区人民南路XX号',
      establishDate: '2012-07-20',
      phone: '020-33445566',
      employeeCount: 250,
      disabledCount: 4,
      collectionYear: '2025年',
      district: '武侯区'
    }
  ];

  // 模拟历年缴纳记录
  private getPaymentRecords(unitId: string): PaymentRecord[] {
    return [
      { year: '2025年', payableAmount: 180000, paidAmount: 180000, status: '已缴', payDate: '2025-04-15' },
      { year: '2024年', payableAmount: 175000, paidAmount: 175000, status: '已缴', payDate: '2024-04-10' },
      { year: '2023年', payableAmount: 160000, paidAmount: 160000, status: '已缴', payDate: '2023-04-12' },
      { year: '2022年', payableAmount: 150000, paidAmount: 150000, status: '已缴', payDate: '2022-04-08' }
    ];
  }

  // 模拟减免缓状态
  private getReliefStatus(unitId: string): ReliefStatus[] {
    return [
      {
        type: '减免',
        reason: '企业吸纳残疾人就业比例达到规定标准',
        startDate: '2024-01-01',
        endDate: '2024-12-31',
        amount: 20000,
        status: '已通过'
      },
      {
        type: '缓缴',
        reason: '企业经营困难，申请缓缴',
        startDate: '2023-06-01',
        endDate: '2023-12-31',
        amount: 50000,
        status: '已通过'
      }
    ];
  }

  // 打开弹窗
  private openSheet(type: ArchiveSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  private openArchive(unit: UnitBasicInfo) {
    this.selectedUnit = unit;
    this.openSheet(ArchiveSheetType.PAYMENT_RECORDS);
  }

  // 获取筛选后的列表
  private getFilteredList(): UnitBasicInfo[] {
    let list = this.unitList;

    if (this.selectedDistrict !== 'all') {
      const districtName = this.getSelectedDistrictName();
      list = list.filter(unit => unit.district === districtName);
    }

    if (this.searchKeyword) {
      list = list.filter(unit => unit.companyName.includes(this.searchKeyword));
    }

    return list;
  }

  private getSelectedDistrictName(): string {
    for (let i = 0; i < this.districtList.length; i++) {
      if (this.districtList[i].code === this.selectedDistrict) {
        return this.districtList[i].name;
      }
    }
    return '全市';
  }

  private selectDistrict(code: string) {
    this.selectedDistrict = code;
    this.showDistrictDialog = false;
  }

  // 获取状态颜色
  private getStatusColor(status: string): string {
    switch (status) {
      case '已缴':
      case '已通过':
        return ColorConstants.SUCCESS;
      case '未缴':
      case '审批中':
        return ColorConstants.WARNING;
      case '已拒绝':
        return ColorConstants.DANGER;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  // 获取状态背景色
  private getStatusBgColor(status: string): string {
    switch (status) {
      case '已缴':
      case '已通过':
        return 'rgba(0, 158, 95, 0.1)';
      case '未缴':
      case '审批中':
        return 'rgba(245, 158, 11, 0.1)';
      case '已拒绝':
        return 'rgba(166, 32, 25, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  build() {
    Column() {
      // 搜索框
      Row() {
        TextInput({ placeholder: '搜索单位名称...', text: this.searchKeyword })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .layoutWeight(1)
          .height(40)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_CARD)
          .border({ width: 1, color: ColorConstants.BORDER })
          .borderRadius(8)
          .padding({ left: 12, right: 12 })

        Button('搜索')
          .width(80)
          .height(40)
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor(ColorConstants.PRIMARY)
          .borderRadius(8)
          .margin({ left: 12 })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(`当前地区：${this.getSelectedDistrictName()}`)
          .fontSize(12)
          .fontColor(ColorConstants.PRIMARY)
          .layoutWeight(1)
          .onClick(() => {
            this.showDistrictDialog = !this.showDistrictDialog;
          })
        Text(`共${this.getFilteredList().length}家`)
          .fontSize(12)
          .fontColor(ColorConstants.TEXT_SECONDARY)
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.showDistrictDialog) {
        Column() {
          ForEach(this.districtList, (item: DistrictOption) => {
            Row() {
              Text(item.name)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .layoutWeight(1)
              if (this.selectedDistrict === item.code) {
                SymbolGlyph($r('sys.symbol.checkmark'))
                  .fontSize(16)
                  .fontColor([ColorConstants.PRIMARY])
              }
            }
            .width('100%')
            .padding({ left: 12, right: 12, top: 10, bottom: 10 })
            .onClick(() => {
              this.selectDistrict(item.code);
            })
          })
        }
        .width('100%')
        .padding({ top: 4, bottom: 4 })
        .backgroundColor(ColorConstants.BG_CARD)
        .borderRadius(8)
        .margin({ bottom: 12 })
      }

      // 列表 - 可滚动
      Scroll() {
        Column() {
          ForEach(this.getFilteredList(), (unit: UnitBasicInfo) => {
            Column() {
              // 单位名称和所属区
              Row() {
                Column() {
                  Text(unit.companyName)
                    .fontSize(16)
                    .fontColor(ColorConstants.TEXT_TITLE)
                    .fontWeight(FontWeight.Medium)
                    .margin({ bottom: 4 })

                  Text(unit.district)
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                Text('查看档案')
                  .fontSize(13)
                  .fontColor(ColorConstants.PRIMARY)
                  .fontWeight(FontWeight.Medium)
                  .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                  .onClick(() => {
                    this.openArchive(unit);
                  })
              }
              .width('100%')
              .margin({ bottom: 12 })

              // 详细信息
              Row() {
                Column() {
                  Text('在职职工')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`${unit.employeeCount}人`)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)

                Column() {
                  Text('残疾职工')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(`${unit.disabledCount}人`)
                    .fontSize(14)
                    .fontColor(ColorConstants.PRIMARY)
                }
                .layoutWeight(1)

                Column() {
                  Text('征收年度')
                    .fontSize(12)
                    .fontColor(ColorConstants.TEXT_SECONDARY)
                    .margin({ bottom: 4 })
                  Text(unit.collectionYear)
                    .fontSize(14)
                    .fontColor(ColorConstants.TEXT_TITLE)
                }
                .layoutWeight(1)
              }
              .width('100%')
              .padding(16)
              .backgroundColor(ColorConstants.BG_PAGE)
              .borderRadius(8)
            }
            .width('100%')
            .padding(16)
            .backgroundColor(ColorConstants.BG_CARD)
            .borderRadius(12)
            .shadow({
              radius: 4,
              color: 'rgba(0, 0, 0, 0.06)',
              offsetX: 0,
              offsetY: 2
            })
            .margin({ bottom: 12 })
          })
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
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      title: { title: '单位档案详情' },
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = ArchiveSheetType.NONE;
        this.selectedUnit = null;
      }
    })
  }

  // 统一弹窗构造器
  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === ArchiveSheetType.PAYMENT_RECORDS && this.selectedUnit !== null) {
        Scroll() {
          this.buildArchiveDetail()
        }
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildArchiveDetail() {
    Column() {
      // 单位基本信息
      Text('单位基本信息')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        Row() {
          Text('单位名称：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.companyName)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('统一社会信用代码：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.creditCode)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('法定代表人：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.legalPerson)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('注册地：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.registerAddress)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('成立日期：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.establishDate)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('联系电话：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.phone)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('在职职工数：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(`${this.selectedUnit!.employeeCount}人`)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('残疾职工数：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(`${this.selectedUnit!.disabledCount}人`)
            .fontSize(14)
            .fontColor(ColorConstants.PRIMARY)
        }
        .width('100%')
        .margin({ bottom: 8 })

        Row() {
          Text('征收年度：')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
          Text(this.selectedUnit!.collectionYear)
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_TITLE)
        }
        .width('100%')
      }
      .width('100%')
      .padding(16)
      .backgroundColor(ColorConstants.BG_PAGE)
      .borderRadius(8)
      .margin({ bottom: 20 })

      // 历年缴纳记录
      Text('历年缴纳记录')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        ForEach(this.getPaymentRecords(this.selectedUnit!.id), (record: PaymentRecord) => {
          Row() {
            Column() {
              Text(record.year)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .fontWeight(FontWeight.Medium)
            }
            .layoutWeight(1)

            Column() {
              Text(`应缴：¥${(record.payableAmount / 10000).toFixed(1)}万`)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
            }
            .layoutWeight(1)

            Column() {
              Text(`实缴：¥${(record.paidAmount / 10000).toFixed(1)}万`)
                .fontSize(13)
                .fontColor(ColorConstants.SUCCESS)
            }
            .layoutWeight(1)

            Text(record.status)
              .fontSize(13)
              .fontColor(this.getStatusColor(record.status))
              .padding({ left: 8, right: 8, top: 4, bottom: 4 })
              .backgroundColor(this.getStatusBgColor(record.status))
              .borderRadius(12)
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_CARD)
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
      .margin({ bottom: 20 })

      // 减免缓状态
      Text('减免缓状态')
        .fontSize(18)
        .fontColor(ColorConstants.TEXT_TITLE)
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: 16 })

      Column() {
        ForEach(this.getReliefStatus(this.selectedUnit!.id), (relief: ReliefStatus) => {
          Column() {
            Row() {
              Text(relief.type)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .fontWeight(FontWeight.Medium)

              Text(relief.status)
                .fontSize(12)
                .fontColor(this.getStatusColor(relief.status))
                .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                .backgroundColor(this.getStatusBgColor(relief.status))
                .borderRadius(12)
                .margin({ left: 8 })
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('原因：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(relief.reason)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('期限：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`${relief.startDate} 至 ${relief.endDate}`)
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_TITLE)
            }
            .width('100%')
            .margin({ bottom: 8 })

            Row() {
              Text('金额：')
                .fontSize(13)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(`¥${(relief.amount / 10000).toFixed(1)}万元`)
                .fontSize(13)
                .fontColor(ColorConstants.WARNING)
                .fontWeight(FontWeight.Medium)
            }
            .width('100%')
          }
          .width('100%')
          .padding(12)
          .backgroundColor(ColorConstants.BG_PAGE)
          .borderRadius(8)
          .margin({ bottom: 8 })
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }
}

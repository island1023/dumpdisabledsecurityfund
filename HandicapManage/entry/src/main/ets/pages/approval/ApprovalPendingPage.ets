import { ColorConstants } from '../../common/constants/ColorConstants';
import { get, post } from '../../services/HttpUtil';

interface ApprovalItem {
  id: string;
  companyName: string;
  applyType: string;
  applyDate: string;
  status: string;
  disabledCount?: number;
  amount?: string;
  description?: string;
  employeeName?: string;
  idCard?: string;
  disabilityType?: string;
  disabilityLevel?: string;
  hireDate?: string;
  attachmentName?: string;
  reductionType?: string;
  applyYear?: string;
  applyAmount?: string;
  applyReason?: string;
  reductionAttachment?: string;
}

interface TabItem {
  id: string;
  name: string;
}

enum ApprovalSheetType {
  NONE,
  APPROVE,
  REJECT,
  DETAIL
}

interface ApprovalResponseData {
  list: ApprovalItem[];
  total: number;
}

@Component
export struct ApprovalPendingPage {
  @State searchKeyword: string = '';
  @State activeTab: string = 'all';
  @State isSheetShow: boolean = false;
  @State activeSheet: ApprovalSheetType = ApprovalSheetType.NONE;
  @State selectedApproval: ApprovalItem | null = null;
  @State rejectReason: string = '';
  @State approvalList: ApprovalItem[] = [];
  @State isLoading: boolean = false;

  private tabs: TabItem[] = [
    { id: 'all', name: '全部' },
    { id: 'disabled', name: '残疾职工' },
    { id: 'reduction', name: '减免缓' }
  ];

  aboutToAppear() {
    this.loadApprovalList();
  }

  async loadApprovalList() {
    this.isLoading = true;
    try {
      const params: Record<string, string | number | boolean> = {};
      params.page = 1;
      params.pageSize = 50;
      if (this.activeTab !== 'all') {
        params.type = this.activeTab;
      }
      const response = await get<ApprovalResponseData>('/approval/pending', params);
      if (response.code === 200) {
        this.approvalList = response.data.list;
      }
    } catch (error) {
      console.error('加载审批列表失败:', error);
    } finally {
      this.isLoading = false;
    }
  }

  private openSheet(type: ApprovalSheetType) {
    this.activeSheet = type;
    this.isSheetShow = true;
  }

  build() {
    Column() {
      Row() {
        ForEach(this.tabs, (tab: TabItem) => {
          Column() {
            Text(tab.name)
              .fontSize(14)
              .fontColor(this.activeTab === tab.id ? ColorConstants.PRIMARY : ColorConstants.TEXT_BODY)
              .fontWeight(this.activeTab === tab.id ? FontWeight.Bold : FontWeight.Normal)

            if (this.activeTab === tab.id) {
              Divider()
                .width(24)
                .height(2)
                .color(ColorConstants.PRIMARY)
                .margin({ top: 4 })
            }
          }
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .padding({ left: 16, right: 16 })
          .onClick(() => {
            this.activeTab = tab.id;
            this.loadApprovalList();
          })
        })
      }
      .width('100%')
      .height(44)
      .backgroundColor(ColorConstants.BG_CARD)
      .border({ width: { bottom: 1 }, color: ColorConstants.BORDER })
      .margin({ bottom: 16 })

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
          .onClick(() => {
            this.loadApprovalList();
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      if (this.isLoading) {
        Column() {
          Text('加载中...')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.approvalList.length === 0) {
        Column() {
          Text('暂无待审批数据')
            .fontSize(14)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column() {
            ForEach(this.getFilteredList(), (item: ApprovalItem) => {
              Column() {
                Row() {
                  Column() {
                    Text(item.companyName)
                      .fontSize(16)
                      .fontColor(ColorConstants.TEXT_TITLE)
                      .fontWeight(FontWeight.Medium)
                      .margin({ bottom: 4 })

                    Text(`申请类型：${item.applyType}`)
                      .fontSize(13)
                      .fontColor(this.getApplyTypeColor(item.applyType))
                      .fontWeight(FontWeight.Medium)
                  }
                  .alignItems(HorizontalAlign.Start)
                  .layoutWeight(1)

                  Text(item.status)
                    .fontSize(13)
                    .fontColor(this.getStatusColor(item.status))
                    .fontWeight(FontWeight.Medium)
                    .padding({ left: 12, right: 12, top: 4, bottom: 4 })
                    .backgroundColor(this.getStatusBgColor(item.status))
                    .borderRadius(12)
                }
                .width('100%')
                .margin({ bottom: 12 })

                Column() {
                  Row() {
                    Text('申请年份：')
                      .fontSize(13)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                    Text(item.applyDate)
                      .fontSize(13)
                      .fontColor(ColorConstants.TEXT_TITLE)
                  }
                  .width('100%')
                  .margin({ bottom: 8 })

                  if (item.disabledCount) {
                    Row() {
                      Text('残疾职工：')
                        .fontSize(13)
                        .fontColor(ColorConstants.TEXT_SECONDARY)
                      Text(`${item.disabledCount} 人`)
                        .fontSize(13)
                        .fontColor(ColorConstants.TEXT_TITLE)
                        .fontWeight(FontWeight.Medium)
                    }
                    .width('100%')
                    .margin({ bottom: 8 })
                  }

                  if (item.amount) {
                    Row() {
                      Text('申请金额：')
                        .fontSize(13)
                        .fontColor(ColorConstants.TEXT_SECONDARY)
                      Text(item.amount)
                        .fontSize(13)
                        .fontColor(ColorConstants.PRIMARY)
                        .fontWeight(FontWeight.Bold)
                    }
                    .width('100%')
                    .margin({ bottom: 8 })
                  }

                  Row() {
                    Text('备注：')
                      .fontSize(13)
                      .fontColor(ColorConstants.TEXT_SECONDARY)
                    Text(item.description || '-')
                      .fontSize(13)
                      .fontColor(ColorConstants.TEXT_TITLE)
                  }
                  .width('100%')
                  .margin({ bottom: 16 })

                  Row() {
                    Button('驳回')
                      .layoutWeight(1)
                      .height(36)
                      .fontSize(14)
                      .fontColor(ColorConstants.DANGER)
                      .backgroundColor(ColorConstants.BG_PAGE)
                      .border({ width: 1, color: ColorConstants.DANGER })
                      .borderRadius(6)
                      .margin({ right: 8 })
                      .onClick(() => {
                        this.selectedApproval = item;
                        this.openSheet(ApprovalSheetType.REJECT);
                      })

                    Button('通过')
                      .layoutWeight(1)
                      .height(36)
                      .fontSize(14)
                      .fontColor('#FFFFFF')
                      .backgroundColor(ColorConstants.SUCCESS)
                      .borderRadius(6)
                      .margin({ left: 8 })
                      .onClick(() => {
                        this.selectedApproval = item;
                        this.openSheet(ApprovalSheetType.APPROVE);
                      })
                  }
                  .width('100%')
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
              .onClick(() => {
                this.selectedApproval = item;
                this.openSheet(ApprovalSheetType.DETAIL);
              })
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
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
    .padding({ left: 16, right: 16, top: 16, bottom: 16 })
    .bindSheet($$this.isSheetShow, this.sheetBuilder(), {
      detents: [SheetSize.MEDIUM, SheetSize.LARGE],
      preferType: SheetType.BOTTOM,
      showClose: true,
      onDisappear: () => {
        this.isSheetShow = false;
        this.activeSheet = ApprovalSheetType.NONE;
        this.selectedApproval = null;
        this.rejectReason = '';
      }
    })
  }

  @Builder
  sheetBuilder() {
    Column() {
      if (this.activeSheet === ApprovalSheetType.APPROVE) {
        this.buildApproveDialog()
      } else if (this.activeSheet === ApprovalSheetType.REJECT) {
        this.buildRejectDialog()
      } else if (this.activeSheet === ApprovalSheetType.DETAIL) {
        this.buildDetailDialog()
      }
    }
    .padding({ top: 20 })
  }

  @Builder
  buildApproveDialog() {
    Column() {
      if (this.selectedApproval) {
        Text('确认通过该审批申请？')
          .fontSize(16)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 16 })

        Column() {
          Row() {
            Text('单位名称：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.companyName)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请类型：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.applyType)
              .fontSize(14)
              .fontColor(this.getApplyTypeColor(this.selectedApproval.applyType))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.isSheetShow = false;
            })

          Button('确认通过')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(ColorConstants.SUCCESS)
            .borderRadius(8)
            .margin({ left: 8 })
            .onClick(() => {
              this.handleConfirmApprove();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }

  @Builder
  buildRejectDialog() {
    Column() {
      if (this.selectedApproval) {
        Text('驳回理由')
          .fontSize(16)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Medium)
          .width('100%')
          .margin({ bottom: 16 })

        Column() {
          Row() {
            Text('单位名称：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.companyName)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请类型：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.applyType)
              .fontSize(14)
              .fontColor(this.getApplyTypeColor(this.selectedApproval.applyType))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 16 })

        TextArea({ placeholder: '请输入驳回理由，单位将收到通知并修改后重新提交' })
          .width('100%')
          .height(100)
          .fontSize(14)
          .backgroundColor(ColorConstants.BG_PAGE)
          .border({ width: 1, color: ColorConstants.BORDER })
          .borderRadius(8)
          .padding(12)
          .onChange((value: string) => {
            this.rejectReason = value;
          })
          .margin({ bottom: 24 })

        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor(ColorConstants.TEXT_SECONDARY)
            .backgroundColor(ColorConstants.BG_PAGE)
            .border({ width: 1, color: ColorConstants.BORDER })
            .borderRadius(8)
            .margin({ right: 8 })
            .onClick(() => {
              this.isSheetShow = false;
            })

          Button('确认驳回')
            .layoutWeight(1)
            .height(44)
            .fontSize(15)
            .fontColor('#FFFFFF')
            .backgroundColor(ColorConstants.DANGER)
            .borderRadius(8)
            .margin({ left: 8 })
            .onClick(() => {
              this.handleConfirmReject();
            })
        }
        .width('100%')
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }

  @Builder
  buildDetailDialog() {
    Column() {
      if (this.selectedApproval) {
        Column() {
          Row() {
            Text('单位名称：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.companyName)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请类型：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.applyType)
              .fontSize(14)
              .fontColor(this.getApplyTypeColor(this.selectedApproval.applyType))
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请年份：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.applyYear || this.selectedApproval.applyDate)
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
        .margin({ bottom: 16 })

        if (this.selectedApproval.applyType === '残疾职工') {
          this.buildDisabledEmployeeDetail()
        } else if (this.selectedApproval.applyType === '减免缓') {
          this.buildReductionDetail()
        }
      }
    }
    .width('100%')
    .padding({ left: 24, right: 24, top: 24, bottom: 24 })
  }

  @Builder
  buildDisabledEmployeeDetail() {
    if (this.selectedApproval) {
      Column() {
        Text('残疾职工信息')
          .fontSize(16)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 12 })

        Column() {
          Row() {
            Text('姓名：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.employeeName || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('身份证号：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.idCard || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('残疾类型：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.disabilityType || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('残疾等级：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.disabilityLevel || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('入职时间：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.hireDate || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.selectedApproval.attachmentName) {
            Row() {
              Text('附件：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedApproval.attachmentName)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .decoration({ type: TextDecorationType.Underline })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
      }
      .width('100%')
    }
  }

  @Builder
  buildReductionDetail() {
    if (this.selectedApproval) {
      Column() {
        Text('减免缓申请信息')
          .fontSize(16)
          .fontColor(ColorConstants.TEXT_TITLE)
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .margin({ bottom: 12 })

        Column() {
          Row() {
            Text('申请类型：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.reductionType || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
              .fontWeight(FontWeight.Medium)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请年份：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(this.selectedApproval.applyYear || '-')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_TITLE)
          }
          .width('100%')
          .margin({ bottom: 8 })

          Row() {
            Text('申请金额：')
              .fontSize(14)
              .fontColor(ColorConstants.TEXT_SECONDARY)
            Text(`¥${this.selectedApproval.applyAmount || '0'}`)
              .fontSize(14)
              .fontColor(ColorConstants.PRIMARY)
              .fontWeight(FontWeight.Bold)
          }
          .width('100%')
          .margin({ bottom: 12 })

          if (this.selectedApproval.applyReason) {
            Column() {
              Text('申请理由：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
                .width('100%')
                .margin({ bottom: 8 })

              Text(this.selectedApproval.applyReason)
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_TITLE)
                .lineHeight(22)
                .width('100%')
            }
            .width('100%')
            .alignItems(HorizontalAlign.Start)
            .margin({ bottom: 12 })
          }

          if (this.selectedApproval.reductionAttachment) {
            Row() {
              Text('附件：')
                .fontSize(14)
                .fontColor(ColorConstants.TEXT_SECONDARY)
              Text(this.selectedApproval.reductionAttachment)
                .fontSize(14)
                .fontColor(ColorConstants.PRIMARY)
                .decoration({ type: TextDecorationType.Underline })
            }
            .width('100%')
          }
        }
        .width('100%')
        .padding(16)
        .backgroundColor(ColorConstants.BG_PAGE)
        .borderRadius(8)
      }
      .width('100%')
    }
  }

  private getFilteredList(): ApprovalItem[] {
    let list = this.approvalList;

    if (this.activeTab !== 'all') {
      const typeMap: Record<string, string> = {
        'disabled': '残疾职工',
        'reduction': '减免缓'
      };
      list = list.filter(item => item.applyType === typeMap[this.activeTab]);
    }

    if (this.searchKeyword) {
      list = list.filter(item => item.companyName.includes(this.searchKeyword));
    }

    return list;
  }

  private getApplyTypeColor(type: string): string {
    switch (type) {
      case '残疾职工':
        return ColorConstants.SUCCESS;
      case '减免缓':
        return ColorConstants.WARNING;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  private getStatusColor(status: string): string {
    switch (status) {
      case '待审批':
        return ColorConstants.WARNING;
      case '已通过':
        return ColorConstants.SUCCESS;
      case '已驳回':
        return ColorConstants.DANGER;
      default:
        return ColorConstants.TEXT_TITLE;
    }
  }

  private getStatusBgColor(status: string): string {
    switch (status) {
      case '待审批':
        return 'rgba(245, 158, 11, 0.1)';
      case '已通过':
        return 'rgba(0, 158, 95, 0.1)';
      case '已驳回':
        return 'rgba(213, 45, 59, 0.1)';
      default:
        return ColorConstants.BG_PAGE;
    }
  }

  private async handleConfirmApprove() {
    if (this.selectedApproval) {
      try {
        const requestData: Record<string, Object> = {};
        const response = await post(`/approval/${this.selectedApproval.id}/approve`, requestData);
        if (response.code === 200) {
          this.loadApprovalList();
          this.isSheetShow = false;
        }
      } catch (error) {
        console.error('审批通过失败:', error);
      }
    }
  }

  private async handleConfirmReject() {
    if (this.selectedApproval && this.rejectReason.trim()) {
      try {
        const rejectData: Record<string, Object> = {};
        rejectData.reason = this.rejectReason as Object;
        const response = await post(`/approval/${this.selectedApproval.id}/reject`, rejectData);
        if (response.code === 200) {
          this.loadApprovalList();
          this.isSheetShow = false;
        }
      } catch (error) {
        console.error('审批驳回失败:', error);
      }
    } else {
      console.log('请填写驳回理由');
    }
  }
}

import { ColorConstants } from '../../common/constants/ColorConstants';
import { appViewModel } from '../../viewmodel/AppViewModel';
import { GovernmentStatCard, GovernmentDataBoard } from '../../common/components/GovernmentCardComponents';
import { CollectionService } from '../../services/CollectionService';
import { CollectionStatistics } from '../../models/CollectionModel';

interface QuickAction {
  id: string;
  name: string;
  icon: string;
  color: string;
}

/**
 * 首页
 */
@Component
export struct HomePage {
 @State statistics: CollectionStatistics | null = null;
 @State loading: boolean = true;
 @State currentYear: number = new Date().getFullYear();

 async aboutToAppear() {
 await this.loadStatistics();
 }

 async loadStatistics() {
 this.loading = true;
 try {
 this.statistics = await CollectionService.getCollectionStatistics(this.currentYear);
 } catch (error) {
 console.error('加载统计数据失败', error);
 } finally {
 this.loading = false;
 }
 }

 /**
 * 根据用户角色显示不同的快捷入口
 */
 getQuickActions(): Array<QuickAction> {
 const role = appViewModel.currentUser?.role || '';

 if (appViewModel.isAdmin()) {
 return [
 { id: 'unit', name: '单位审批', icon: 'building.2', color: ColorConstants.PRIMARY },
 { id: 'collection', name: '征收核算', icon: 'doc.text', color: ColorConstants.WARNING },
 { id: 'notice', name: '通知单打印', icon: 'bell', color: ColorConstants.SUCCESS },
 { id: 'report', name: '统计报表', icon: 'chart.pie', color: '#6B7280' }
 ] as Array<QuickAction>;
 } else if (appViewModel.isLeader()) {
 return [
 { id: 'supervision', name: '资金监管', icon: 'chart.bar', color: ColorConstants.PRIMARY },
 { id: 'report', name: '统计报表', icon: 'chart.pie', color: ColorConstants.WARNING },
 { id: 'unit', name: '单位查看', icon: 'building.2', color: ColorConstants.SUCCESS }
 ] as Array<QuickAction>;
 } else if (appViewModel.isUnit()) {
 return [
 { id: 'unit', name: '信息申报', icon: 'building.2', color: ColorConstants.PRIMARY },
 { id: 'collection', name: '缴款查看', icon: 'doc.text', color: ColorConstants.WARNING }
 ] as Array<QuickAction>;
 }

 return [];
 }

 build() {
  Column() {
 //数据统计区域
 if (this.loading) {
 Column() {
 LoadingProgress()
 .width(40)
 .height(40)
 .color(ColorConstants.PRIMARY)
 }
 .width('100%')
 .height(200)
 .justifyContent(FlexAlign.Center)
 } else if (this.statistics) {
 Column() {
 // 年度选择
 Row() {
 Text(`${this.currentYear}年度征收概况`)
 .fontSize(18)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.TEXT_TITLE)

 Blank()

 Row() {
 Text('切换年度')
 .fontSize(14)
 .fontColor(ColorConstants.PRIMARY)
 SymbolGlyph($r('sys.symbol.chevron_down'))
 .fontSize(16)
 .fontColor([ColorConstants.PRIMARY])
 .margin({ left:4 })
 }
 .onClick(() => {
 // 显示年度选择
 })
 }
 .width('100%')
 .padding({ left:16, right:16, top:16, bottom:12 })

 // 统计卡片
 Row() {
 GovernmentStatCard({
 title: '应缴单位',
 value: this.statistics.totalUnits.toString(),
 unit: '家',
 icon: 'building_2',
 color: ColorConstants.PRIMARY
 })

 GovernmentStatCard({
 title: '已缴单位',
 value: this.statistics.paidUnits.toString(),
 unit: '家',
 icon: 'checkmark_circle',
 color: ColorConstants.SUCCESS
 })
 }
 .width('100%')
 .padding({ left:16, right:16 })
 .justifyContent(FlexAlign.SpaceBetween)

 Row() {
 GovernmentStatCard({
 title: '未缴单位',
 value: this.statistics.unpaidUnits.toString(),
 unit: '家',
 icon: 'exclamationmark_triangle',
 color: ColorConstants.WARNING
 })

 GovernmentStatCard({
 title: '应缴总额',
 value: (this.statistics.totalAmount /10000).toFixed(1),
 unit: '万元',
 icon: 'dollarsign_circle',
 color: ColorConstants.PRIMARY
 })
 }
 .width('100%')
 .padding({ left:16, right:16, top:12 })
 .justifyContent(FlexAlign.SpaceBetween)

 Row() {
 GovernmentStatCard({
 title: '已缴总额',
 value: (this.statistics.paidAmount /10000).toFixed(1),
 unit: '万元',
 icon: 'checkmark_seal',
 color: ColorConstants.SUCCESS
 })

 GovernmentStatCard({
 title: '减免总额',
 value: (this.statistics.reductionAmount /10000).toFixed(1),
 unit: '万元',
 icon: 'minus_circle',
 color: '#6B7280'
 })
 }
 .width('100%')
 .padding({ left:16, right:16, top:12 })
 .justifyContent(FlexAlign.SpaceBetween)
 }
 .width('100%')
 .backgroundColor(ColorConstants.BG_PAGE)
 }

 // 快捷入口
 Column() {
 Text('快捷入口')
 .fontSize(18)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.TEXT_TITLE)
 .width('100%')
 .padding({ left:16, right:16, top:16, bottom:12 })

 Row() {
 ForEach(this.getQuickActions(), (action: QuickAction) => {
 Column() {
 Column() {
 SymbolGlyph($r('sys.symbol.' + action.icon.replace('.', '_')))
 .fontSize(32)
 .fontColor([action.color])
 }
 .width(56)
 .height(56)
 .backgroundColor(ColorConstants.BG_PAGE)
 .borderRadius(28)
 .justifyContent(FlexAlign.Center)

 Text(action.name)
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_BODY)
 .margin({ top:8 })
 }
 .layoutWeight(1)
 .padding({ top:12, bottom:12 })
 .onClick(() => {
 // 跳转到对应页面
 })
 })
 }
 .width('100%')
 .backgroundColor(ColorConstants.BG_CARD)
 .borderRadius(8)
 .margin({ left:16, right:16 })
 }
 .width('100%')
 .margin({ top:16 })

 // 待办事项（管理员可见）
 if (appViewModel.isAdmin()) {
 Column() {
 Text('待办事项')
 .fontSize(18)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.TEXT_TITLE)
 .width('100%')
 .padding({ left:16, right:16, top:16, bottom:12 })

 Column() {
 Row() {
 Row() {
 Text('3')
 .fontSize(20)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.PRIMARY)
 Text('项待审批')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .margin({ left:8 })
 }
 .layoutWeight(1)

 Text('查看')
 .fontSize(14)
 .fontColor(ColorConstants.PRIMARY)
 }
 .width('100%')
 .padding(16)
 .backgroundColor(ColorConstants.BG_CARD)
 .borderRadius(8)
 .margin({ left:16, right:16, bottom:8 })

 Row() {
 Row() {
 Text('2')
 .fontSize(20)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.WARNING)
 Text('项待核销')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_BODY)
 .margin({ left:8 })
 }
 .layoutWeight(1)

 Text('查看')
 .fontSize(14)
 .fontColor(ColorConstants.WARNING)
 }
 .width('100%')
 .padding(16)
 .backgroundColor(ColorConstants.BG_CARD)
 .borderRadius(8)
 .margin({ left:16, right:16 })
 }
 .width('100%')
 .margin({ top:16 })
 }

 // 最近动态
 Column() {
 Text('最近动态')
 .fontSize(18)
 .fontWeight(FontWeight.Bold)
 .fontColor(ColorConstants.TEXT_TITLE)
 .width('100%')
 .padding({ left:16, right:16, top:16, bottom:12 })

 Column() {
 Row() {
 Column() {
 Text('广州科技发展有限公司')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_TITLE)
 .fontWeight(FontWeight.Medium)

 Text('完成缴款60000元')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ top:4 })
 }
 .layoutWeight(1)

 Text('2025-04-15')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 }
 .width('100%')
 .padding(16)
 .borderRadius(8)

 Row() {
 Column() {
 Text('珠江商贸集团')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_TITLE)
 .fontWeight(FontWeight.Medium)

 Text('提交减免缓申请')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ top:4 })
 }
 .layoutWeight(1)

 Text('2025-04-14')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 }
 .width('100%')
 .padding(16)
 .borderRadius(8)

 Row() {
 Column() {
 Text('白云制造有限公司')
 .fontSize(14)
 .fontColor(ColorConstants.TEXT_TITLE)
 .fontWeight(FontWeight.Medium)

 Text('单位信息待审批')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 .margin({ top:4 })
 }
 .layoutWeight(1)

 Text('2025-04-13')
 .fontSize(12)
 .fontColor(ColorConstants.TEXT_SECONDARY)
 }
 .width('100%')
 .padding(16)
 .borderRadius(8)
 }
 .width('100%')
 .backgroundColor(ColorConstants.BG_CARD)
 .borderRadius(8)
 .margin({ left:16, right:16 })
 }
 .width('100%')
 .margin({ top:16 })
 }

 // 底部空白
 Column()
 .height(24)
 }
 .width('100%')
 .height('100%')
 .backgroundColor(ColorConstants.BG_PAGE)
 }
}

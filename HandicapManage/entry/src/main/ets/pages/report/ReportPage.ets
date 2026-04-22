import { ColorConstants } from '../../common/constants/ColorConstants';
import { GovernmentTableCard } from '../../common/components/GovernmentCardComponents';

/**
 * 统计报表页面
 */
@Component
export struct ReportPage {
  build() {
    Column() {
      GovernmentTableCard({
        title: '统计报表',
        showHeader: true,
        showPagination: false
      }) {
        Column() {
          Text('统计报表功能已迁移到新的通知单报表页面')
            .fontSize(16)
            .fontColor(ColorConstants.TEXT_SECONDARY)
        }
        .width('100%')
        .height(200)
        .justifyContent(FlexAlign.Center)
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(ColorConstants.BG_PAGE)
    .padding({ left: 24, right: 24, top: 16, bottom: 16 })
  }
}
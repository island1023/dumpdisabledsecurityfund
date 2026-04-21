import { router } from '@kit.ArkUI';
import { ColorConstants } from '../common/constants/ColorConstants';

/**
 * 应用入口页面
 * 自动跳转到登录页面
 */
@Entry
@Component
struct Index {
  aboutToAppear() {
    // 应用启动时自动跳转到登录页面
    setTimeout(() => {
      router.replaceUrl({
        url: 'pages/LoginPage'
      });
    }, 100);
  }

  build() {
    Column() {
      // 启动页内容
      Column() {
        SymbolGlyph($r('sys.symbol.house_fill'))
          .fontSize(80)
          .fontColor([ColorConstants.PRIMARY])
          .margin({ bottom: 24 })

        Text('残疾人就业保障金')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1D2129')
          .margin({ bottom: 8 })

        Text('征收及监管系统')
          .fontSize(16)
          .fontColor('#4E5969')

        // 加载指示器
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#C71C22')
          .margin({ top: 32 })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F7F8FA')
  }
}
// 这是一个简单的测试文件，用于验证ArkTS语法
@Component
struct TestComponent {
  @State message: string = 'Hello Test';

  build() {
    Column() {
      Text(this.message)
        .fontSize(20)
        .fontColor('#1D2129')
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }
}
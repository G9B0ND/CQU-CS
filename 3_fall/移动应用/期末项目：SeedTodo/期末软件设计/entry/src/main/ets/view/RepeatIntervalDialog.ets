import CommonConstants from '../common/constants/CommonConstants';
import ArrayUtil from '../common/util/ArrayUtil';

@CustomDialog
export default struct RepeatIntervalDialog {

  /**
   * 对话框控制器。
   */
  public controller: CustomDialogController;
  /**
   * 进入页面时的重复周期。
   */
  @Link
  private repeatInterval: Array<boolean>;
  /**
   * 当前被选中的临时重复周期。
   */
  @State
  private tmpRepeatInterval: Array<boolean> = [false, false, false, false, false, false, false];

  /**
   * 将进入页面时的重复周期复制到临时重复周期。
   */
  public aboutToAppear(): void {
    this.tmpRepeatInterval = ArrayUtil.copy(this.repeatInterval);
  }

  public build(): void {
    Column() {
      Text('重复周期');
      ForEach(CommonConstants.WEEK_DAYS, (value: string, index: number) => {
        Row() {
          Text(value);
          Blank();
          Toggle({ type: ToggleType.Switch, isOn: this.tmpRepeatInterval[index] })
            .onChange((isOn: boolean) => {
              if (isOn) {
                this.tmpRepeatInterval[index] = true;
              } else {
                this.tmpRepeatInterval[index] = false;
              }
            });
        };
      }, (value: string) => value);

      Row() {
        Button('取消')
          .fontColor($r('app.color.red'))
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            this.controller.close();
          });
        Divider()
          .vertical(true)
          .color($r('app.color.font_grey'))
          .height('48%');
        Button('确认')
          .backgroundColor(Color.Transparent)
          .fontColor($r('app.color.blue'))
          .onClick(() => {
            this.repeatInterval = this.tmpRepeatInterval;
            this.controller.close();
          });
      }
      .size({ width: '100%', height: '6%' })
      .justifyContent(FlexAlign.SpaceEvenly);
    }
    .backgroundColor($r('app.color.main_background'))
    .padding('2%')
    .size({ width: '100%', height: '48%' });
  }
}
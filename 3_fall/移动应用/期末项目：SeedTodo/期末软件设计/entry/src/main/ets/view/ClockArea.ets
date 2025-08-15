/*
 * Copyright (c) 2022 Huawei Device Co., Ltd.
 * Licensed under the Apache License,Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
import MainConstant from '../common/constants/MainConstant';
import DimensionUtil from '../common/util/DimensionUtil';


@Component
export default struct ClockArea {
  /**
   * 表示显示时钟或者时间文字。
   */
  @State
  private showClock: boolean = true;

  /**
   * 绘图更新周期。
   */
  private drawInterval: number = -1;

  /**
   * 时钟大小
   */
  private canvasSize: number = DimensionUtil.getVp($r('app.float.clock_size'));
  private canvasSize1: number = DimensionUtil.getVp($r('app.float.clock_size_1'));
  private clockRadius: number = this.canvasSize / 2 - 2;
  private settings: RenderingContextSettings = new RenderingContextSettings(true);
  private renderContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.settings);

  /**
   * 页面退出时暂停绘制任务。
   */
  public aboutToDisappear(): void {
    clearInterval(this.drawInterval);
  }

  public build(): void {
    Stack() {
      Column()
        .size({ width:  this.canvasSize1, height: this.canvasSize })
        .opacity(0.8)
        .backgroundColor($r('app.color.main_background'));
      Canvas(this.renderContext)
        .width(this.canvasSize)
        .aspectRatio(1)
        .onReady(() => {
          if (this.drawInterval === -1) {
            this.startDrawTask();
          }
        })
        .onClick(() => {
          this.showClock = !this.showClock;
        })
        .backgroundColor(Color.Transparent);
    }
    .backgroundImage($r('app.media.backclock'))
    .backgroundImageSize({width:'100%',height:'100%'})
    .shadow({
      radius: 10,
      color: `rgba(0,0,0,0.5)`,
      offsetX:10,
      offsetY:10
    })
    .clip(new Rect({
      width: DimensionUtil.getVp($r('app.float.clock_size_1')),
      height: DimensionUtil.getVp($r('app.float.clock_size')),
      radius: 10 // 设置圆角半径，可根据需求调整
    }));
  }

  /**
   * 启动绘画任务。
   */
  private startDrawTask(): void {
    this.renderContext.translate(
      this.canvasSize / 2,
      this.canvasSize / 2);
    this.drawClockArea();
    this.drawInterval = setInterval(() => {
      this.drawClockArea();
    }, 40);
  }

  /**
   * 开始绘制时钟区域。
   */
  private drawClockArea(): void {
    this.renderContext.clearRect(
      -this.canvasSize,
      -this.canvasSize / 2,
      this.canvasSize * 2,
      this.canvasSize);
    let date = new Date();
    let hours = date.getHours();
    let minutes = date.getMinutes();
    let seconds = date.getSeconds();
    let milliseconds = date.getMilliseconds();
    if (this.showClock) {
      this.drawPan();
      this.drawPointer(
        30 * (hours > 12
          ? hours - 12
          : hours)
        + minutes / 2
        + seconds / 120
        + milliseconds / 120000
        , MainConstant.HOUR_POINTER_IMAGE_URL);
      this.drawPointer(6 * minutes + seconds / 10 + milliseconds / 10000, MainConstant.MINUTE_POINTER_IMAGE_URL);
      this.drawPointer(6 * seconds + milliseconds * 6 / 1000, MainConstant.SECOND_POINTER_IMAGE_URL);
    } else {
      this.drawTime(hours, minutes, seconds);
    }
  }

  /**
   * 绘制表盘。
   */
  private drawPan(): void {
    this.renderContext.beginPath();
    let secondImg = new ImageBitmap(MainConstant.CLOCK_PAN_IMAGE_URL);
    let imgWidth = this.clockRadius * 2;
    this.renderContext.drawImage(secondImg, -this.clockRadius, -this.clockRadius, imgWidth, imgWidth);
    this.renderContext.restore();
  }

  /**
   * 绘制时针、分针、秒针。
   * @param degree 指针转动的角度。
   * @param pointerImgRes 指针图片地址。
   */
  private drawPointer(degree: number, pointerImgRes: string): void {
    this.renderContext.save();
    let theta = (degree + MainConstant.DEFAULT_HORIZONTAL_ANGLE) * Math.PI / MainConstant.DEFAULT_HORIZONTAL_ANGLE;
    this.renderContext.rotate(theta);
    this.renderContext.beginPath();
    let secondImg = new ImageBitmap(pointerImgRes);
    let imgWidth = 10;
    this.renderContext.drawImage(
      secondImg,
      -imgWidth / 2,
      -this.clockRadius,
      imgWidth,
      this.clockRadius * 2);
    this.renderContext.restore();
  }

  /**
   * 绘制完整时间回显。
   * @param hour 当前的小时数。
   * @param minute 当前的分钟数。
   * @param second 当前的秒数。
   */
  private drawTime(hour: number, minute: number, second: number): void {
    let time = (hour > 9 ? hour : ('0' + hour)) + ':'
    + (minute > 9 ? minute : ('0' + minute)) + ':'
    + (second > 9 ? second : ('0' + second));
    this.renderContext.save();
    this.renderContext.font = DimensionUtil.getPx($r('app.float.clock_time_font_size'))
    + MainConstant.CLOCK_TIME_FONT_SIZE_UNIT;
    this.renderContext.beginPath();
    this.renderContext.textAlign = 'center';
    this.renderContext.fillText(time, 0, 0);
    this.renderContext.restore();
  }
}
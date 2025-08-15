import router from '@ohos.router';
import scheduleTable from '../common/database/ScheduleTable';
import ArrayUtil from '../common/util/ArrayUtil';
import Schedule from '../model/Schedule';
import SortRule from '../model/SortRule';

@Entry
@Component
struct SearchSchedule {
  /**
   * 当前登录的用户名。
   */
  @State
  private username: string = '';

  /**
   * 用户搜索的关键字。
   */
  @State @Watch('getSchedules')
  private searchValue: string = '';

  /**
   * 所有用户端所有日程信息。
   */
  @State @Watch('getSchedules')
  private allSchedules: Array<Schedule> = [];

  /**
   * 当前用户的所有日程信息。
   */
  @State
  private schedules: Array<Schedule> = [];

  /**
   * ScheduleItem 组件的初始高度。用于实现属性动画。
   */
  private scheduleItemHeight: string = '10%';

  /**
   * ScheduleItem 组件的实际高度。用于实现属性动画。
   */
  @State
  private animationFinishedListHeight: string = this.scheduleItemHeight;

  /**
   * 关系型数据库管理。
   */
  private scheduleTable: scheduleTable = new scheduleTable();


  /**
   * 页面跳转动画。
   */
  public pageTransition(): void {
    PageTransitionEnter({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Right);
    PageTransitionExit({ type: RouteType.None, duration: 400 })
      .slide(SlideEffect.Right);
  }


  /**
   * 初始化用户名、日程记录数据。
   */
  public aboutToAppear(): void {
    if (Object(router.getParams())?.['username']) {
      this.username = Object(router.getParams())['username'];
    }

    this.scheduleTable.getRdbStore(() => {
      this.scheduleTable.queryData(SortRule.DEFAULT, (results: Array<Schedule>) => {
        this.allSchedules = results;
      });
    });
  }

  public build(): void {
    Column() {
      Row() {
        Button() {
          Image($r('app.media.ic_public_back'))
            .size({ width: 24, height: 24 })
            .fillColor($r('app.color.font_black'));
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.pushUrl({
            url: 'pages/FoldersList',
            params: {
              username: this.username
            }
          });
        });
        TextInput({ placeholder: '搜索' })
          .onChange((value: string) => {
            this.searchValue = value;
          })
          .width('92%');
      }
      .size({ width: '100%', height: '6%' })
      .margin('2%')
      .justifyContent(FlexAlign.SpaceBetween)
      .margin({top:'10%'});

      List() {
        ListItemGroup() {
          ForEach(ArrayUtil.subArray(this.schedules, (value: Schedule): boolean =>!value.isFinished),
            (schedule: Schedule) => {
              ListItem() {
                this.ScheduleItem(schedule);
              }
              .swipeAction({
                start: this.ItemSwipeLeft(schedule),
                end: this.ItemSwipeRight(schedule),
                edgeEffect: SwipeEdgeEffect.Spring
              })
              .size({ height: this.scheduleItemHeight });
            }, (schedule: Schedule) => JSON.stringify(schedule));
        };

        if (ArrayUtil.subArray(this.schedules, (value: Schedule): boolean => value.isFinished).length > 0) {
          ListItemGroup({ header: this.ScheduleItemHeader() }) {
            ForEach(ArrayUtil.subArray(this.schedules, (value: Schedule): boolean => value.isFinished === true),
              (schedule: Schedule) => {
                ListItem() {
                  this.ScheduleItem(schedule);
                }
                .visibility(this.animationFinishedListHeight === '0%'
                  ? Visibility.Hidden : Visibility.Visible)
                .swipeAction({
                  start: this.ItemSwipeLeft(schedule),
                  end: this.ItemSwipeRight(schedule),
                  edgeEffect: SwipeEdgeEffect.Spring
                })
                .enabled(this.animationFinishedListHeight === this.scheduleItemHeight)
                .size({
                  width: this.animationFinishedListHeight === '0%' ? '0%' : '100%',
                  height: this.animationFinishedListHeight
                });
              }, (schedule: Schedule) => JSON.stringify(schedule));
          };
        }
      }
      .chainAnimation(true)
      .sticky(StickyStyle.Header)
      .edgeEffect(EdgeEffect.Spring)
      .border({ radius: 12, color: $r('app.color.pure_white') })
      .height('86%')
      .alignListItem(ListItemAlign.Center)
      .scrollBar(BarState.Off);
    }
    .padding({ left: '2%', right: '2%' })
    .backgroundImage($r('app.media.backgroundedit'))
    .backgroundImageSize({ width: '100%', height: '100%' });
  }

  /**
   * 已完成的 ScheduleItem 组件所在 ListItemGroup 的标题组件。
   */
  @Builder
  private ScheduleItemHeader(): void {
    Row() {
      Text('已完成')
        .fontWeight(FontWeight.Medium)
        .fontSize(14)
        .fontColor($r('app.color.font_black'));
    }
    .padding('1%')
    .size({ width: '96%', height: '4%' })
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .margin('2%')
    .backgroundColor($r('app.color.pure_white'))
    .opacity(0.6)
    .onClick(() => {
      animateTo({ duration: 400, curve: Curve.Smooth },
        () => this.animationFinishedListHeight =
          this.animationFinishedListHeight === this.scheduleItemHeight
          ? '0%' : this.scheduleItemHeight);
    });
  }

  /**
   * 列表中，每一条日程记录对应一个 ScheduleItem 组件。
   * @param schedule 组件对应的日程记录。
   */
  @Builder
  private ScheduleItem(schedule: Schedule): void {
    Row({ space: '2%' }) {
      Button() {
        if (schedule.isFinished) {
          Image($r('app.media.circle_filled'))
            .fillColor($r('app.color.blue'))
            .size({ width: 24, height: 24 })
        } else {
          Image($r('app.media.circle'))
            .fillColor($r('app.color.font_grey'))
            .size({ width: 24, height: 24 });
        }
      }
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        let index = this.allSchedules.indexOf(schedule);
        if (index === -1) {
          console.error('[hxk] MyDay no schedule in allSchedules');
        }
        this.allSchedules[index].isFinished = !this.allSchedules[index].isFinished;
        this.getSchedules();
        this.scheduleTable.updateData(this.allSchedules[index], () => {
        });
      });
      Column() {
        Row({ space: 8 }) {
          Text(schedule.scheduleName)
            .fontSize(16)
            .fontWeight(FontWeight.Normal)
            .fontColor(schedule.isFinished
              ? $r('app.color.font_grey')
              : $r('app.color.font_black'))
            .decoration(schedule.isFinished
              ? {
                  type: TextDecorationType.LineThrough,
                  color: $r('app.color.font_grey')
                }
              : {
                  type: TextDecorationType.None,
                });

          if (schedule.isMyDay) {
            Row() {
              Image($r('app.media.my_day'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
              Text('今日代办')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            };
          }

          Text(schedule.description)
            .fontSize(14)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.font_grey'));
        };

        Row({ space: 8 }) {
          Text(schedule.folderName.length === 0 ? '日程' : schedule.folderName)
            .fontSize(14)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.font_grey'));
          if (schedule.steps.length > 0) {
            Text('共' + schedule.steps.length + '步')
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
          }
          if (schedule.endYear > 0) {
            Row() {
              Image($r('app.media.in_plan'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
              Text(this.getEndTimeText(schedule))
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            };
          }
          if (schedule.remindTime.length > 0) {
            Row() {
              Image($r('app.media.ring'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
            };
          }
          if (!ArrayUtil.equalTo(schedule.repeatInterval, [false, false, false, false, false, false, false])) {
            Row() {
              Image($r('app.media.repeat'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
              Text('定期重复')
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            };
          }
        }
      }
      .alignItems(HorizontalAlign.Start);

      Blank();

      Column() {
        Button() {
          Row() {
            Text('紧急')
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
            Image(schedule.isUrgent
              ? $r('app.media.ic_public_topping_filled')
              : $r('app.media.ic_public_topping'))
              .size({ width: 24, height: 24 })
              .fillColor(schedule.isUrgent
                ? $r('app.color.red')
                : $r('app.color.font_grey'));
          };
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          let index = this.allSchedules.indexOf(schedule);
          if (index === -1) {
            console.error('[hxk] MyDay no schedule in allSchedules');
          }
          this.allSchedules[index].isUrgent = !this.allSchedules[index].isUrgent;
          this.getSchedules();
          this.scheduleTable.updateData(this.allSchedules[index], () => {
          });
        });

        Button() {
          Row() {
            Text('重要')
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
            Image(schedule.isImportant
              ? $r('app.media.star_filled')
              : $r('app.media.star'))
              .size({ width: 24, height: 24 })
              .fillColor(schedule.isImportant
                ? $r('app.color.blue')
                : $r('app.color.font_grey'));
          };
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          let index = this.allSchedules.indexOf(schedule);
          if (index === -1) {
            console.error('[hxk] MyDay no schedule in allSchedules');
          }
          this.allSchedules[index].isImportant = !this.allSchedules[index].isImportant;
          this.getSchedules();
          this.scheduleTable.updateData(this.allSchedules[index], () => {
          });
        });
      }
      .alignItems(HorizontalAlign.End);
    }
    .opacity(0.95)
    .border({
      radius: 12,
      style: BorderStyle.Solid,
      color: $r('app.color.font_grey')
    })
    .size({ width: '96%' })
    .padding('2%')
    .justifyContent(FlexAlign.SpaceEvenly)
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.main_background'))
    .onClick(() => {
      router.pushUrl({
        url: 'pages/EditSchedule',
        params: {
          schedule: schedule
        }
      })
    });
  }

  /**
   * ListItem 右滑显示的组件。将对应日程移动至（或移出）“今日代办”。
   * @param schedule 组件对应的日程记录
   */
  @Builder
  private ItemSwipeLeft(schedule: Schedule): void {
    Row() {
      Image($r('app.media.my_day'))
        .size({ width: 24, height: 24 })
        .fillColor($r('app.color.pure_white'));
    }
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.blue'))
    .size({ width: '100%', height: '100%' })
    .onClick(() => {
      schedule.isMyDay = !schedule.isMyDay;
      this.allSchedules[this.allSchedules.findIndex(
        (value: Schedule): boolean => value.id === schedule.id)] = schedule;
      this.scheduleTable.updateData(schedule, () => {
      });
      this.getSchedules();
    });
  }

  /**
   * ListItem 左滑显示的组件。将对应日程删除。
   * @param schedule 组件对应的日程记录
   */
  @Builder
  private ItemSwipeRight(schedule: Schedule): void {
    Row() {
      Image($r('app.media.ic_contacts_delete'))
        .size({ width: 24, height: 24 })
        .fillColor($r('app.color.pure_white'));
    }
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.red'))
    .size({ width: '100%', height: '100%' })
    .onClick(() => {
      let index: number = this.allSchedules.findIndex(
        (value: Schedule): boolean => value.id === schedule.id);
      this.allSchedules.splice(index, 1);
      this.scheduleTable.deleteData(schedule, () => {
      });
      AlertDialog.show({
        message: '已删除日程',
        autoCancel: true,
        alignment: DialogAlignment.Bottom,
        offset: { dx: 0, dy: -24 },
        primaryButton: {
          value: '撤销',
          fontColor: $r('app.color.blue'),
          action: () => {
            this.scheduleTable.insertData(schedule, (id: number) => {
              schedule.id = id;
              this.allSchedules.push(schedule);
              this.getSchedules();
            });
          }
        }
      });
    });
  }

  /**
   * allSchedules 或 getSchedules 改变时触发。
   * 根据关键字搜索相关日程。
   */
  private getSchedules(): void {
    this.schedules = ArrayUtil.subArray(this.allSchedules,
      (value: Schedule): boolean => value.username === this.username
      && (value.scheduleName.includes(this.searchValue)
      || value.description.includes(this.searchValue)));
  }

  /**
   * 结束时间字符串。
   */
  private getEndTimeText(schedule: Schedule): string {
    if (schedule.endYear === 0) {
      console.error('[hxk] MyDay getEndTimeText err');
      return ''
    }
    else {
      return schedule.endMonth + '月' + schedule.endDate + '日';
    }
  }
}
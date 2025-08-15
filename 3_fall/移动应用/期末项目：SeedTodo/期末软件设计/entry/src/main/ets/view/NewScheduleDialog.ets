import reminderAgentManager from '@ohos.reminderAgentManager';
import notificationManager from '@ohos.notificationManager';
import CommonConstants from '../common/constants/CommonConstants';
import scheduleTable from '../common/database/ScheduleTable';
import ArrayUtil from '../common/util/ArrayUtil';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import Schedule from '../model/Schedule';
import FolderDialog from './FolderDialog';
import RepeatIntervalDialog from './RepeatIntervalDialog';
import abilityAccessCtrl from '@ohos.abilityAccessCtrl';
import router from '@ohos.router';

@CustomDialog
export default struct NewScheduleDialog {

  /**
   * 页面跳转的来源文件夹。
   */
  @Link
  private sourceFolder: Folder;

  /**
   * 所有用户的日程数据。
   */
  @Link
  private allSchedules: Array<Schedule>;

  /**
   * 提醒时间按钮显示的文字。
   */
  @State
  private remindButtonText: string = '提醒我';

  /**
   * 重复周期按钮显示的文字。
   */
  @State
  private repeatButtonText: string = '重复';

  /**
   * 重复周期。
   */
  @State @Watch('getRepeatButtonText')
  private repeatInterval: Array<boolean> =
    [false, false, false, false, false, false, false];

  /**
   * 当前时间。
   */
  private currentTime: Date = new Date();

  /**
   * 提醒时间。
   */
  private remindTime: Date = new Date();

  /**
   * 正在被创建的新日程。
   */
  @State
  private newSchedule: Schedule = {
    id: -1,
    username: '',
    folderName: '',
    scheduleName: '',
    steps: [],
    endYear: 0,
    endMonth: 0,
    endDate: 0,
    remindTime: '',
    isAlarmRemind: false,
    reminderId: -1,
    repeatInterval: [false, false, false, false, false, false, false],
    description: '',
    isMyDay: false,
    isImportant: false,
    isUrgent: false,
    isFinished: false
  };

  /**
   * 关系型数据库管理。
   */
  private scheduleTable!: scheduleTable;

  /**
   * 选择新日程所在的文件夹。
   */
  private folderDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: true,
    builder: FolderDialog({ folder: $sourceFolder, newSchedule: $newSchedule }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  /**
   * 选择重复周期。
   */
  private repeatIntervalDialogController: CustomDialogController = new CustomDialogController({
    autoCancel: false,
    builder: RepeatIntervalDialog({ repeatInterval: $repeatInterval }),
    alignment: DialogAlignment.Bottom,
    customStyle: true
  });

  /**
   * 对话框控制器。
   */
  private controller: CustomDialogController;

  /**
   * 根据页面跳转的来源文件夹补充新日程的相关信息。
   */
  public aboutToAppear(): void {
    this.newSchedule.username = this.sourceFolder.owner;
    this.newSchedule.folderName = this.sourceFolder.folderType === FolderType.NORMAL
      ? this.sourceFolder.folderName : '';
    switch (this.sourceFolder.folderType) {
      case FolderType.NORMAL:
        this.newSchedule.folderName = this.sourceFolder.folderName;
        break;
      case FolderType.MY_DAY:
        this.newSchedule.isMyDay = true;
        break;
      case FolderType.IN_PLAN:
        this.newSchedule.endYear = this.currentTime.getFullYear();
        this.newSchedule.endMonth = this.currentTime.getMonth();
        this.newSchedule.endDate = this.currentTime.getDate();
        break;
      case FolderType.IMPORTANT:
        this.newSchedule.isImportant = true;
        break;
      case FolderType.URGENT:
        this.newSchedule.isUrgent = true;
        break;
    }
  }

  public build(): void {
    Column() {
      Row({ space: 4 }) {
        Button() {
          Image($r('app.media.ic_public_edit_black'))
            .fillColor($r('app.color.font_grey'))
            .size({ width: 24, height: 24 });
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          router.replaceUrl({
            url: 'pages/EditSchedule',
            params: {
              folder: this.sourceFolder,
              schedule: this.newSchedule
            }
          });
        });
        TextInput()
          .onChange((value: string) => {
            this.newSchedule.scheduleName = value;
          })
          .width('84%');
        Button() {
          Image($r('app.media.ic_public_add_black'))
            .fillColor(this.newSchedule.scheduleName.length > 0
              ? $r('app.color.blue')
              : $r('app.color.font_grey'))
            .size({ width: 24, height: 24 });
        }
        .backgroundColor(Color.Transparent)
        .enabled(this.newSchedule.scheduleName.length > 0)
        .onClick(() => {
          this.newSchedule.repeatInterval = this.repeatInterval;
          let reminder: reminderAgentManager.ReminderRequestCalendar | reminderAgentManager.ReminderRequestAlarm;
          if (this.newSchedule.isAlarmRemind) {
            reminder = {
              reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
              hour: this.remindTime.getHours(),
              minute: this.remindTime.getMinutes(),
              daysOfWeek: [],
              actionButton: [
                {
                  title: '关闭',
                  type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
                },
                {
                  title: "稍后提醒",
                  type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
                }
              ],
              wantAgent: {
                pkgName: 'com.my_calendar',
                abilityName: 'com.my_calendar.EntryAbility'
              },
              maxScreenWantAgent: {
                pkgName: 'com.my_calendar',
                abilityName: 'com.my_calendar.EntryAbility'
              },
              ringDuration: 20,
              snoozeTimes: 2,
              timeInterval: 5,
              title: '今日日程:' + this.newSchedule.scheduleName,
              content: this.newSchedule.description,
              expiredContent: '提醒已过期',
              snoozeContent: '稍后提醒',
              slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION,
            };
          } else {
            reminder = {
              reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
              dateTime: {
                year: this.remindTime.getFullYear(),
                month: this.remindTime.getMonth() + 1,
                day: this.remindTime.getDate(),
                hour: this.remindTime.getHours(),
                minute: this.remindTime.getMinutes(),
                second: this.remindTime.getSeconds()
              },
              repeatMonths: [],
              repeatDays: [],
              actionButton: [
                {
                  title: '关闭',
                  type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_CLOSE
                },
                {
                  title: "稍后提醒",
                  type: reminderAgentManager.ActionButtonType.ACTION_BUTTON_TYPE_SNOOZE
                }
              ],
              wantAgent: {
                pkgName: 'com.my_calendar',
                abilityName: 'com.my_calendar.EntryAbility'
              },
              maxScreenWantAgent: {
                pkgName: 'com.my_calendar',
                abilityName: 'com.my_calendar.EntryAbility'
              },
              ringDuration: 20,
              snoozeTimes: 2,
              timeInterval: 5,
              title: '今日日程:' + this.newSchedule.scheduleName,
              content: this.newSchedule.description,
              expiredContent: '提醒已过期',
              snoozeContent: '稍后提醒',
              slotType: notificationManager.SlotType.SOCIAL_COMMUNICATION
            };
            if (this.newSchedule.remindTime.length > 0) {
              reminderAgentManager.publishReminder(reminder, (err, reminderId) => {
                if (err) {
                  console.debug('[hxk] NewScheduleDialog reminderRequestCalendar err: ' + JSON.stringify(err));
                } else {
                  this.newSchedule.reminderId = reminderId;
                  this.scheduleTable.insertData(this.newSchedule, (id: number | boolean) => {
                    if (id === false) {
                      console.error('[hxk] NewScheduleDialog newSchedule insert failed: ' + JSON.stringify(this.newSchedule));
                    } else {
                      this.newSchedule.id = id as number;
                      console.debug('[hxk] NewScheduleDialog newSchedule: ' + JSON.stringify(this.newSchedule));
                      this.allSchedules.push(this.newSchedule);
                    }
                    // this.newSchedule.folderName = '';
                    this.controller.close();
                  });
                }
              });
            } else {
              this.scheduleTable.insertData(this.newSchedule, (id: number | boolean) => {
                if (id === false) {
                  console.error('[hxk] NewScheduleDialog newSchedule insert failed.');
                } else {
                  this.newSchedule.id = id as number;
                  console.debug('[hxk] NewScheduleDialog newSchedule: ' + JSON.stringify(this.newSchedule));
                  this.allSchedules.push(this.newSchedule);
                }
                // this.newSchedule.folderName = '';
                this.controller.close();
              });
            }
          }
        });
      };

      Scroll() {
        Row({ space: '16' }) {
          if (this.sourceFolder.folderType !== FolderType.NORMAL) {
            Button() {
              Row() {
                Image($r('app.media.home'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text(this.newSchedule.folderName.length === 0 ? '文件夹' : this.newSchedule.folderName)
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
              };
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.folderDialogController.open();
            });
          }

          Row() {
            Button() {
              Row() {
                Image($r('app.media.in_plan'))
                  .size({ width: 20, height: 20 })
                  .fillColor($r('app.color.font_grey'));
                Text(this.newSchedule.endYear === 0
                  ? '截止日期'
                  : this.getEndDateString())
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor($r('app.color.font_grey'));
                if (this.newSchedule.endYear > 0) {
                  Image($r('app.media.cancel'))
                    .size({ width: 16, height: 16 })
                    .fillColor($r('app.color.red'))
                    .onClick(() => {
                      this.newSchedule.endYear = 0;
                      this.newSchedule.endMonth = 0;
                      this.newSchedule.endDate = 0;
                    });
                }
              };
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              DatePickerDialog.show({
                start: new Date(),
                end: new Date('2030-12-31'),
                lunar: false,
                onAccept: (value: DatePickerResult) => {
                  this.newSchedule.endYear = value.year;
                  this.newSchedule.endMonth = value.month! + 1;
                  this.newSchedule.endDate = value.day;
                }
              });
            });
          };
          Button() {
            Row() {
              Image($r('app.media.ring'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
              Text(this.remindButtonText)
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
            };
          }
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            abilityAccessCtrl.createAtManager()
              .requestPermissionsFromUser(getContext(),
                ['ohos.permission.PUBLISH_AGENT_REMINDER']);
          })
          .bindMenu(this.RemindTimeMenu());

          if (this.newSchedule.remindTime.length > 0) {
            Button() {
              Row() {
                Text('闹钟提醒')
                  .fontSize(14)
                  .fontWeight(FontWeight.Normal)
                  .fontColor(this.newSchedule.isAlarmRemind
                    ? $r('app.color.font_grey')
                    : $r('app.color.blue'));
                Checkbox()
                  .select(this.newSchedule.isAlarmRemind)
                  .size({ width: 16, height: 16 })
              };
            }
            .backgroundColor(Color.Transparent)
            .onClick(() => {
              this.newSchedule.isAlarmRemind = !this.newSchedule.isAlarmRemind;
            });
          }

          Button() {
            Row() {
              Image($r('app.media.repeat'))
                .size({ width: 20, height: 20 })
                .fillColor($r('app.color.font_grey'));
              Text(this.repeatButtonText)
                .fontSize(14)
                .fontWeight(FontWeight.Normal)
                .fontColor($r('app.color.font_grey'));
              if (!ArrayUtil.equalTo(this.repeatInterval, [false, false, false, false, false, false, false])) {
                Image($r('app.media.cancel'))
                  .size({ width: 16, height: 16 })
                  .fillColor($r('app.color.red'))
                  .onClick(() => {
                    this.repeatInterval = [false, false, false, false, false, false, false];
                  });
              }
            };
          }
          .backgroundColor(Color.Transparent)
          .bindMenu(this.RepeatIntervalMenu());
        };
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off);
    }
    .backgroundColor($r('app.color.main_background'))
    .size({ width: '100%', height: '8%' });
  }

  /**
   * 选择提醒时间菜单栏。
   */
  @Builder
  private RemindTimeMenu(): void {
    List() {
      ListItem() {
        Row() {
          Image($r('app.media.remind_today'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('今日晚些时候' +
          (CommonConstants.DEFAULT_REMIND_TIME.find(
            (value: number) => this.currentTime.getHours() < value) !== undefined
            ? ('（' + ((CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) ?? 0) < 10 ? '0' : '') +
            CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) + ':00）')
            : ''))
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) !== undefined
              ? $r('app.color.font_black') : $r('app.color.font_grey'))
            .enabled(CommonConstants.DEFAULT_REMIND_TIME.find(
              (value: number) => this.currentTime.getHours() < value) !== undefined)
            .onClick(() => {
              this.currentTime = new Date();
              let remindToday = CommonConstants.DEFAULT_REMIND_TIME.find(
                (value: number) => this.currentTime.getHours() < value);
              this.remindTime.setHours(remindToday!, 0, 0, 0);
              this.newSchedule.remindTime = JSON.stringify(this.remindTime);
              this.getRemindButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.remind_tomorrow'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('明天（' + CommonConstants.WEEK_DAYS[this.currentTime.getDay()] + ') 09:00')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.currentTime = new Date();
              this.remindTime.setDate(this.currentTime.getDate() + 1);
              this.remindTime.setHours(9, 0, 0, 0);
              this.newSchedule.remindTime = JSON.stringify(this.remindTime);
              this.getRemindButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.pick_date'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('选择日期和时间')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.currentTime = new Date();
              DatePickerDialog.show({
                start: this.currentTime,
                end: new Date('2030-12-31'),
                lunar: false,
                onAccept: (value: DatePickerResult) => {
                  this.remindTime.setFullYear(value.year);
                  this.remindTime.setMonth(value.month);
                  this.remindTime.setDate(value.day);
                  TimePickerDialog.show({
                    useMilitaryTime: true,
                    selected: this.newSchedule.remindTime.length === 0
                      ? new Date(this.currentTime.valueOf() + 1000 * 60 * 60)
                      : this.remindTime,
                    onAccept: (value: TimePickerResult) => {
                      this.remindTime.setHours(value.hour, value.minute, 0, 0);
                      this.newSchedule.remindTime = JSON.stringify(this.remindTime);
                      this.getRemindButtonText();
                    }
                  });
                }
              });
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      if (this.newSchedule.remindTime.length > 0) {
        ListItem() {
          Row() {
            Image($r('app.media.ic_public_delete_red'))
              .fillColor($r('app.color.red'))
              .size({ width: 24, height: 24 });
            Text('清除提醒时间')
              .fontSize(16)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.font_black'))
              .onClick(() => {
                this.newSchedule.remindTime = '';
                this.remindTime = this.currentTime;
                this.getRemindButtonText();
              });
          }
          .size({ height: '4%' });
        }
        .margin('2%');
      }
    }
    .padding('2%')
    .size({ width: '84%' });
  }

  /**
   * 选择重复周期菜单栏。
   */
  @Builder
  private RepeatIntervalMenu(): void {
    List() {
      ListItem() {
        Row() {
          Image($r('app.media.repeat_daily'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('每天')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [true, true, true, true, true, true, true];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekdays'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('工作日')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [true, true, true, true, true, false, false];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekends'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('周末')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [false, false, false, false, false, true, true];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.repeat_weekly'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('每周' + CommonConstants.WEEK_DAYS[(this.currentTime.getDay() + 6) % 7])
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatInterval = [
                0 === (this.currentTime.getDay() + 6) % 7,
                1 === (this.currentTime.getDay() + 6) % 7,
                2 === (this.currentTime.getDay() + 6) % 7,
                3 === (this.currentTime.getDay() + 6) % 7,
                4 === (this.currentTime.getDay() + 6) % 7,
                5 === (this.currentTime.getDay() + 6) % 7,
                6 === (this.currentTime.getDay() + 6) % 7,
              ];
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');

      ListItem() {
        Row() {
          Image($r('app.media.pick_date'))
            .fillColor($r('app.color.font_black'))
            .size({ width: 24, height: 24 });
          Text('自定义')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('app.color.font_black'))
            .onClick(() => {
              this.repeatIntervalDialogController.open();
              this.getRepeatButtonText();
            });
        }
        .size({ height: '4%' });
      }
      .margin('2%');
    }
    .padding('2%')
    .size({ width: '84%' });
  }

  /**
   * 重复周期按钮显示的文本。
   */
  private getRepeatButtonText(): void {
    if (ArrayUtil.equalTo(this.repeatInterval, [false, false, false, false, false, false, false])) {
      this.repeatButtonText = '重复';
    } else if (ArrayUtil.equalTo(this.repeatInterval, [true, true, true, true, true, true, true])) {
      this.repeatButtonText = '每天';
    } else if (ArrayUtil.equalTo(this.repeatInterval, [true, true, true, true, true, false, false])) {
      this.repeatButtonText = '工作日';
    } else if (ArrayUtil.equalTo(this.repeatInterval, [false, false, false, false, false, true, true])) {
      this.repeatButtonText = '周末';
    } else {
      let repeatButtonText = '每周:';
      this.repeatInterval.forEach((value: boolean, index: number) => {
        if (value) {
          repeatButtonText = repeatButtonText + CommonConstants.WEEK_DAYS[index] + ',';
        }
      });
      if (repeatButtonText[repeatButtonText.length - 1] === ',') {
        this.repeatButtonText = repeatButtonText.slice(0, repeatButtonText.length - 1);
      }
    }
  }

  /**
   * 提醒时间按钮显示的文本。
   */
  private getRemindButtonText(): void {
    if (this.newSchedule.remindTime.length === 0) {
      this.remindButtonText = '提醒我';
    } else if (this.remindTime.getDate() === this.currentTime.getDate()) {
      this.remindButtonText = '在今日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else if (this.remindTime.getDate() === this.currentTime.getDate() + 1) {
      this.remindButtonText = '在明日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else if (this.remindTime.getFullYear() === this.currentTime.getFullYear()) {
      this.remindButtonText = '在' +
      (this.remindTime.getMonth() + 1) + '月' +
      this.remindTime.getDate() + '日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    } else {
      this.remindButtonText = '在' +
      this.remindTime.getFullYear() + '年' +
      (this.remindTime.getMonth() + 1) + '月' +
      this.remindTime.getDate() + '日' +
      (this.remindTime.getHours() < 10 ? '0' : '') + this.remindTime.getHours() +
      ':' + (this.remindTime.getMinutes() < 10 ? '0' : '') + this.remindTime.getMinutes() +
      '时提醒我';
    }
  }

  /**
   * 结束时间按钮显示的文本。
   */
  private getEndDateString(): string {
    if (this.newSchedule.endYear === this.currentTime.getFullYear()
    && this.newSchedule.endMonth === this.currentTime.getMonth() + 1
    && this.newSchedule.endDate === this.currentTime.getDate()) {
      return '今日到期';
    } else if (this.newSchedule.endYear === this.currentTime.getFullYear()
    && this.newSchedule.endMonth === this.currentTime.getMonth() + 1
    && this.newSchedule.endDate === this.currentTime.getDate() + 1) {
      return '明日到期';
    } else {
      return this.newSchedule.endMonth + '月' + this.newSchedule.endDate + '日到期';
    }
  }
}
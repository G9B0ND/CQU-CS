import CommonConstants from '../common/constants/CommonConstants';
import PreferencesUtil from '../common/database/PreferencesUtil';
import ArrayUtil from '../common/util/ArrayUtil';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';
import Schedule from '../model/Schedule';

@CustomDialog
export default struct FolderDialog {

  /**
   * 所有文件夹。
   */
  @State @Watch('getFolders')
  private allFolders: Array<Folder> = [];

  /**
   * 当前用户的所有文件夹。
   */
  @State
  private folders: Array<Folder> = [];

  /**
   * 页面跳转的来源文件夹。
   */
  @Link
  private folder: Folder;

  /**
   * 正在创建的新日程。
   */
  @Link
  private newSchedule: Schedule;

  /**
   * 对话框控制器。
   */
  private controller: CustomDialogController;

  /**
   * 获取文件夹信息。
   */
  public aboutToAppear(): void {
    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
      .then((value: string) => {
        this.allFolders = JSON.parse(value) as Array<Folder>;
      });
  }

  public build(): void {
    Column() {
      Row() {
        Text('选择文件夹');
        Blank();
        Button() {
          Image($r('app.media.ic_public_ok_black'))
            .size({ width: 28, height: 28 })
            .fillColor($r('app.color.blue'));
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.controller.close();
        });
      }
      .size({ width: '100%' });

      Row({ space: 8 }) {
        Button() {
          Row() {
            Text('紧急')
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
            Image(this.newSchedule.isUrgent
              ? $r('app.media.ic_public_topping_filled')
              : $r('app.media.ic_public_topping'))
              .size({ width: 24, height: 24 })
              .fillColor(this.newSchedule.isUrgent
                ? $r('app.color.red')
                : $r('app.color.font_grey'));
          };
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.newSchedule.isUrgent = !this.newSchedule.isUrgent;
        });

        Button() {
          Row() {
            Text('重要')
              .fontSize(14)
              .fontWeight(FontWeight.Normal)
              .fontColor($r('app.color.font_grey'));
            Image(this.newSchedule.isImportant
              ? $r('app.media.star_filled')
              : $r('app.media.star'))
              .size({ width: 24, height: 24 })
              .fillColor(this.newSchedule.isImportant
                ? $r('app.color.blue')
                : $r('app.color.font_grey'));
          };
        }
        .backgroundColor(Color.Transparent)
        .onClick(() => {
          this.newSchedule.isImportant = !this.newSchedule.isImportant;
        });
      }
      .size({ width: '96%' })
      .margin('2%');

      Divider();

      ForEach(
        ArrayUtil.subArray(this.folders,
          (value: Folder) => value.folderType === FolderType.NORMAL),
        (folder: Folder) => {
          Text(folder.folderName)
            .fontSize(14)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.font_grey'))
            .onClick(() => {
              this.newSchedule.folderName = folder.folderName;
              this.controller.close();
            })
            .margin('2%');
        }, (folder: Folder) => JSON.stringify(folder));
    }
    .padding('2%')
    .backgroundColor($r('app.color.main_background'));
  }

  /**
   * allFolders 改变时触发。
   * 获取当前用户创建的文件夹。
   */
  public getFolders(): void {
    this.folders = ArrayUtil.subArray(this.allFolders,
      (folder: Folder) => folder.owner === this.folder.owner && folder.folderType === FolderType.NORMAL);
  }
}
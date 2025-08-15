import CommonConstants from '../common/constants/CommonConstants';
import PreferencesUtil from '../common/database/PreferencesUtil';
import ArrayUtil from '../common/util/ArrayUtil';
import Folder from '../model/Folder';
import FolderType from '../model/FolderType';

@CustomDialog
export default struct SelectFolderDialog {

  /**
   * 所有文件夹数据。
   */
  @State @Watch('getFolders')
  private allFolders: Array<Folder> = [];

  /**
   * 当前用户创建的文件夹。
   */
  @State
  private folders: Array<Folder> = [];

  /**
   * 页面跳转的来源文件夹。
   */
  @Link
  private sourceFolder: Folder;

  /**
   * 被选中（用于移动或复制日程）的文件夹。
   */
  @Link
  private selectedFolder: Folder;

  /**
   * 对话框控制器。
   */
  private controller: CustomDialogController;


  /**
   * 初始化文件夹数据。
   */
  public aboutToAppear(): void {
    PreferencesUtil.getPreferences(CommonConstants.FOLDER_PREFERENCES, [])
      .then((value: string) => {
        this.allFolders = JSON.parse(value) as Array<Folder>;
      });
  }

  /**
   * allFolders 改变时触发。
   * 获取当前用户创建的所有文件夹。
   */
  public getFolders(): void {
    this.folders = ArrayUtil.subArray(this.allFolders,
      (folder: Folder) => folder.owner === this.sourceFolder.owner && folder.folderType === FolderType.NORMAL);
  }

  public build(): void {
    Column() {
      Row() {
        Text('选择文件夹')
          .alignSelf(ItemAlign.Start);
      }
      .size({ width: '100%' });

      Text('全部日程')
        .fontSize(14)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.font_grey'))
        .onClick(() => {
          this.selectedFolder = {
            folderType: null!,
            folderName: '',
            background: null!,
            backgroundType: null!,
            owner: null!
          };
          this.controller.close();
        })
        .margin('2%');

      Divider()
        .color($r('app.color.font_grey'))
        .margin('2%');

      ForEach(
        ArrayUtil.subArray(this.folders,
          (value: Folder) => value.folderType === FolderType.NORMAL),
        (folder: Folder) => {
          Text(folder.folderName)
            .fontSize(14)
            .fontWeight(FontWeight.Normal)
            .fontColor($r('app.color.font_grey'))
            .onClick(() => {
              this.selectedFolder = folder;
              this.controller.close();
            })
            .margin('2%');
        }, (folder: Folder) => JSON.stringify(folder));
    }
    .padding('2%')
    .backgroundColor($r('app.color.main_background'));
  }
}
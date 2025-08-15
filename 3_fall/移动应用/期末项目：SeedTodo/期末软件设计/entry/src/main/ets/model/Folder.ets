import BackgroundType from './BackgroundType';
import FolderType from './FolderType';

/**
 * 文件夹数据类型。
 */
export default interface Folder {
  owner: string;
  folderName: string;
  folderType: FolderType;
  background: Resource | string;
  backgroundType: BackgroundType
}
/**
 * 关系型数据库数据表。
 */
export default interface Table {
  tableName: string;
  sqlCreate: string;
  columns: Array<string>;
}
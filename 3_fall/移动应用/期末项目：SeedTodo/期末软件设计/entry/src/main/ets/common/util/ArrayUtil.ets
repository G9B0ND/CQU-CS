/**
 * 数组辅助操作工具函数类。
 */
export default class ArrayUtil {
  /**
   * 求满足条件的子数组。
   * @param arr 原数组。
   * @param predicates 筛选条件。
   * @returns 满足条件的子数组。
   */
  static subArray<value_type>(
    arr: Array<value_type>,
    predicates: (value: value_type) => boolean
  ): Array<value_type> {
    let results: Array<value_type> = [];
    arr.forEach((value: value_type) => {
      if (predicates(value)) {
        results.push(value);
      }
    });
    return results;
  }

  /**
   * 根据数组中的每一对值而不是数组的地址判断数组是否相等。
   * @param one 被比较的数组。
   * @param other 被比较的数组。
   * @returns 相等则返回 true，不相等则返回 false。
   */
  static equalTo<value_type>(one: Array<value_type>, other: Array<value_type>): boolean {
    if (one.length != other.length) {
      return false;
    } else {
      let n = one.length;
      for (let i = 0; i < n; ++ i) {
        if (one[i] !== other[i]) {
          return false;
        }
      }
      return true;
    }
  }

  /**
   * 复制数组的每一个值，而不是得到数组的引用。
   * @param arr 被复制的数组。
   * @returns 复制得到的数组。
   */
  static copy<value_type>(arr: Array<value_type>): Array<value_type> {
    let result: Array<value_type> = [];
    arr.forEach((value: value_type) => result.push(value));
    return result;
  }
}
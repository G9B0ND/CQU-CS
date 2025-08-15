/**
 * 排序规则类型。
 */
enum SortRule {
  DEFAULT = 0,
  IMPORTANCE_ASC,
  IMPORTANCE_DESC,
  URGENCY_ASC,
  URGENCY_DESC,
  END_TIME_ASC,
  END_TIME_DESC,
  ALPHABET_ASC,
  ALPHABET_DESC
}

export default SortRule;
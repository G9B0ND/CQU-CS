/**
 * 天气数据类型。与高德地图天气 API 请求结果向对应。
 */
export default interface WeatherData {
  province?: string;
  city?: string;
  adcode?: string;
  weather?: string;
  temperature?: string;
  winddirection?: string;
  windpower?: string;
  humidity?: string;
  reporttime?: string;
  temperature_float?: string;
  humidity_float?: string;
}

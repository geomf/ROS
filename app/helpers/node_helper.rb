module NodeHelper

  SM_A = 6378137.0

  def convert_lon_to_mercator(old_lon)
    lon_rad = (old_lon.to_f / 180.0 * Math::PI)

    return SM_A * lon_rad * 100
  end

  def convert_lat_to_mercator(old_lat)
    lat_rad = (old_lat.to_f / 180.0 * Math::PI)
    return SM_A * Math.log((Math.sin(lat_rad) + 1) / Math.cos(lat_rad)) * 100
  end

  def convert_lon_from_mercator(old_lon)
    lon_rad = old_lon.to_f / 100 / SM_A
    return lon_rad * 180.0 / Math::PI

  end

  def convert_lat_from_mercator(old_lat)
    lat_rad = Math.atan(Math.exp(old_lat.to_f / 100 /SM_A))
    return lat_rad * 180.0 / Math::PI * 2 - 90
  end

  def in_world?
#    return false if lat < -90 || lat > 90
#    return false if lon < -180 || lon > 180
    true
  end
end
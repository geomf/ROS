class BoundingBox
  attr_reader :min_lon, :min_lat, :max_lon, :max_lat

  LON_LIMIT = 180.0
  LAT_LIMIT = 90.0

  public

  def initialize(min_lon, min_lat, max_lon, max_lat)
    @min_lon = min_lon.to_f unless min_lon.nil?
    @min_lat = min_lat.to_f unless min_lat.nil?
    @max_lon = max_lon.to_f unless max_lon.nil?
    @max_lat = max_lat.to_f unless max_lat.nil?
  end

  def self.from_bbox_params(params)
    if params[:bbox] && params[:bbox].count(',') == 3
      bbox_array = params[:bbox].split(',')
    end
    from_bbox_array(bbox_array)
  end

  def get_polygon
    "'POLYGON((#{max_lon} #{min_lat}, #{max_lon} #{max_lat}, #{min_lon} #{max_lat}, #{min_lon} #{min_lat}, #{max_lon} #{min_lat}))'"
  end

=begin
  def check_boundaries
    # check the bbox is sane
    if min_lon > max_lon
      fail OSM::APIBadBoundingBox.new(
               "The minimum longitude must be less than the maximum longitude, but it wasn't")
    end
    if min_lat > max_lat
      fail OSM::APIBadBoundingBox.new(
               "The minimum latitude must be less than the maximum latitude, but it wasn't")
    end
    if min_lon < -LON_LIMIT || min_lat < -LAT_LIMIT || max_lon > +LON_LIMIT || max_lat > +LAT_LIMIT
      fail OSM::APIBadBoundingBox.new("The latitudes must be between #{-LAT_LIMIT} and #{LAT_LIMIT}," +
                                          " and longitudes between #{-LON_LIMIT} and #{LON_LIMIT}")
    end
    self
  end

  def check_size(max_area = MAX_REQUEST_AREA)
    # check the bbox isn't too large
    if area > max_area
      fail OSM::APIBadBoundingBox.new("The maximum bbox size is " + max_area.to_s +
                                          ", and your request was too large. Either request a smaller area, or use planet.osm")
    end
    self
  end

  ##
  # returns area of the bbox as a rough comparative quantity
  def area
    if complete?
      (max_lon - min_lon) * (max_lat - min_lat)
    else
      0
    end
  end
=end

  def width
    max_lon - min_lon
  end

  def height
    max_lat - min_lat
  end

  def to_a
    [min_lon, min_lat, max_lon, max_lat]
  end

  def to_s
    "#{min_lon},#{min_lat},#{max_lon},#{max_lat}"
  end

  def self.from_bbox_array(bbox_array)
=begin
    unless bbox_array
      fail OSM::APIBadUserInput.new(
               "The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat")
    end
=end
    # Take an array of length 4, create a bounding box with min_lon, min_lat, max_lon and
    # max_lat within their respective boundaries.
    min_lon = [[bbox_array[0].to_f, -LON_LIMIT].max, +LON_LIMIT].min
    min_lat = [[bbox_array[1].to_f, -LAT_LIMIT].max, +LAT_LIMIT].min
    max_lon = [[bbox_array[2].to_f, +LON_LIMIT].min, -LON_LIMIT].max
    max_lat = [[bbox_array[3].to_f, +LAT_LIMIT].min, -LAT_LIMIT].max
    BoundingBox.new(min_lon, min_lat, max_lon, max_lat)
  end
end

# Portions Copyright (C) 2015 Intel Corporation

##
# Data structure used for parsing and storing tile bounding box
# It is also responsible for parsing this info from params and validating it
class BoundingBox
  attr_reader :min_lon, :min_lat, :max_lon, :max_lat

  LON_LIMIT = 180.0
  LAT_LIMIT = 90.0
  MAX_REQUEST_AREA = 0.25

  def self.from_bbox_params(params)
    if params[:bbox] && params[:bbox].count(',') == 3
      bbox_array = params[:bbox].split(',')
    end

    fail OSM::APIBadUserInput,
         'The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat' \
      unless bbox_array

    BoundingBox.new(bbox_array[0], bbox_array[1], bbox_array[2], bbox_array[3])
  end

  def initialize(min_lon, min_lat, max_lon, max_lat)
    @min_lon = Validator.read_float(min_lon, 'bounding box min_lon')
    @min_lat = Validator.read_float(min_lat, 'bounding box min_lat')
    @max_lon = Validator.read_float(max_lon, 'bounding box max_lon')
    @max_lat = Validator.read_float(max_lat, 'bounding box max_lat')

    validate_boundaries
    validate_area
  end

  def validate_boundaries
    fail OSM::APIBadBoundingBox,
         "The minimum longitude must be less than the maximum longitude, but it wasn't" \
      if min_lon > max_lon

    fail OSM::APIBadBoundingBox,
         "The minimum latitude must be less than the maximum latitude, but it wasn't" \
      if min_lat > max_lat

    fail OSM::APIBadBoundingBox,
         "The latitudes must be between #{-LAT_LIMIT} and #{LAT_LIMIT}," \
         " and longitudes between #{-LON_LIMIT} and #{LON_LIMIT}" \
      if check_boundaries
  end

  def check_boundaries
    min_lon < -LON_LIMIT || min_lat < -LAT_LIMIT || max_lon > +LON_LIMIT || max_lat > +LAT_LIMIT
  end

  def validate_area
    area = (max_lon - min_lon) * (max_lat - min_lat)

    fail OSM::APIBadBoundingBox,
         "The maximum bbox size is #{MAX_REQUEST_AREA}, and your request was too large. Request a smaller area" \
      if area > MAX_REQUEST_AREA

    fail OSM::APIBadBoundingBox,
         'The bbox size must be grater then 0' \
      if area <= 0
  end

  def polygon_mercator
    "ST_Transform(ST_GeomFromText(#{polygon}, 4326), 900913)"
  end

  def polygon
    "'POLYGON((#{lower_right}, #{upper_right}, #{min_lon} #{max_lat}, #{lower_left}, #{lower_right}))'"
  end

  def lower_right
    "#{max_lon} #{min_lat}"
  end

  def upper_right
    "#{max_lon} #{max_lat}"
  end

  def upper_left
    "#{min_lon} #{max_lat}"
  end

  def lower_left
    "#{min_lon} #{min_lat}"
  end

  def to_s
    "#{min_lon},#{min_lat},#{max_lon},#{max_lat}"
  end
end

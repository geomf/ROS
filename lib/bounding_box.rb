# Portions Copyright (C) 2015 Intel Corporation

class BoundingBox
  attr_reader :min_lon, :min_lat, :max_lon, :max_lat

  LON_LIMIT = 180.0
  LAT_LIMIT = 90.0
  MAX_REQUEST_AREA = 0.25

  def self.from_bbox_params(params)
    if params[:bbox] && params[:bbox].count(',') == 3
      bbox_array = params[:bbox].split(',')
    end
    fail OSM::APIBadUserInput, 'The parameter bbox is required, and must be of the form min_lon,min_lat,max_lon,max_lat' unless bbox_array
    BoundingBox.new(bbox_array[0], bbox_array[1], bbox_array[2], bbox_array[3])
  end

  def initialize(min_lon, min_lat, max_lon, max_lat)
    @min_lon = validate_float(min_lon)
    @min_lat = validate_float(min_lat)
    @max_lon = validate_float(max_lon)
    @max_lat = validate_float(max_lat)

    validate_boundaries
    validate_area
  end

  def validate_float(value)
    Float(value)
  rescue
    raise OSM::APIBadBoundingBox, "All parameters of bounding box must be float type, but it wasn't"
  end

  def validate_boundaries
    fail OSM::APIBadBoundingBox, "The minimum longitude must be less than the maximum longitude, but it wasn't" if min_lon > max_lon
    fail OSM::APIBadBoundingBox, "The minimum latitude must be less than the maximum latitude, but it wasn't" if min_lat > max_lat
    fail OSM::APIBadBoundingBox, "The latitudes must be between #{-LAT_LIMIT} and #{LAT_LIMIT}, and longitudes between #{-LON_LIMIT} and #{LON_LIMIT}" if check_boundaries
  end

  def check_boundaries
    min_lon < -LON_LIMIT || min_lat < -LAT_LIMIT || max_lon > +LON_LIMIT || max_lat > +LAT_LIMIT
  end

  def validate_area
    area = (max_lon - min_lon) * (max_lat - min_lat)
    fail OSM::APIBadBoundingBox, "The maximum bbox size is #{MAX_REQUEST_AREA}, and your request was too large. Request a smaller area" if area > MAX_REQUEST_AREA
    fail OSM::APIBadBoundingBox, 'The bbox size must be grater then 0' if area <= 0
  end

  def polygon
    "'POLYGON((#{max_lon} #{min_lat}, #{max_lon} #{max_lat}, #{min_lon} #{max_lat}, #{min_lon} #{min_lat}, #{max_lon} #{min_lat}))'"
  end

  def to_s
    "#{min_lon},#{min_lat},#{max_lon},#{max_lat}"
  end
end

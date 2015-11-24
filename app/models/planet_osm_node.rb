class PlanetOsmNode < ActiveRecord::Base
  include GeoRecord
  include NodeHelper

  OSM_NAME = 'node'

  def add_additional_nodes(el)
    el['lat'] = convert_lat_from_mercator(self.lat).to_s
    el['lon'] = convert_lon_from_mercator(self.lon).to_s
  end

  def fill_other_fields_using_xml(pt)
    self.lon = convert_lon_to_mercator(pt['lon'])
    self.lat = convert_lat_to_mercator(pt['lat'])
    self.geo_point = create_point_as_geo_element(self.lat, self.lon)
  end

  def check_if_can_be_deleted?
    # TODO: Verify if node is used by any way
    # ways = Way.joins(:way_nodes).where(:current_way_nodes => { :node_id => id }).order(:id)
    # fail OSM::APIPreconditionFailedError.new("Node #{id} is still used by ways #{ways.collect(&:id).join(',')}.") unless ways.empty?
    true
  end

  def validate_element(pt)
    fail OSM::APIBadXMLError.new('node', pt, 'lat missing') if pt['lat'].nil?
    fail OSM::APIBadXMLError.new('node', pt, 'lon missing') if pt['lon'].nil?
    fail OSM::APIBadUserInput.new('The node is outside this world') unless self.in_world?
  end
end

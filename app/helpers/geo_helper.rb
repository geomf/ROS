#
# Rails OMF Server (ROS) Software for visualizing power systems behavior
# Copyright (c) 2015, Intel Corporation.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms and conditions of the GNU General Public License,
# version 2, as published by the Free Software Foundation.
#
# This program is distributed in the hope it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
# more details.
#

##
# Helper module for GeoRecord class
# It stores low level functionality for parsing and writing to xml
module GeoHelper
  SUPER_RELATION_TAGS = %w(spacing conductor_N conductor_A conductor_B conductor_C).freeze
  RELATION_TAGS = %w(configuration spacing conductor_N conductor_A conductor_B conductor_C).freeze

  def add_other_tags_to_xml_node(el)
    tags.each do |key, value|
      add_tag_to_xml(el, 'power:' + key, value) unless RELATION_TAGS.include?(key) || value.nil?
    end
  end

  def add_tag_to_xml(el, key, value)
    tag_el = XML::Node.new 'tag'
    tag_el['k'] = key
    tag_el['v'] = value
    el << tag_el
  end

  def read_tags_from_xml(pt)
    tags = {}
    pt.find('tag').each do |tag|
      validate_tag(pt, tag)
      validate_tag_duplication(tag, tags)
      tag['k'].slice!('power:')
      tags[tag['k']] = tag['v']
    end
    tags
  end

  def pop_tag(name, default = nil)
    fail OSM::APIPreconditionFailedError,
         "Cannot create #{OSM_NAME} with ID=#{id}: data is invalid. No tags for #{name} for with"
      if tags[name].nil?

    value = tags[name] || default
    tags.delete(name)
    value
  end

  def validate_tag(pt, tag)
    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing key') \
      if tag['k'].nil?

    fail OSM::APIBadXMLError.new(self.class, pt, 'tag is missing value') \
      if tag['v'].nil?
  end

  def validate_tag_duplication(tag, tags)
    fail OSM::APIDuplicateTagsError.new('geoElement', id, tag['k']) \
      if tags.include? tag['k']
  end
end

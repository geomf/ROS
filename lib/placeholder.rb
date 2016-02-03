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

class Placeholder
  def self.current
    RequestStore[:placeholder]
  end

  # data structure used for mapping placeholder IDs to real IDs
  def initialize
    @ids = { node: {}, way: {}, relation: {} }
  end

  def store(placeholder_id, new_id, model, xml)
    model_name = model::OSM_NAME

    # when this element is saved it will get a new ID, so we save it
    # to produce the mapping which is sent to other elements.
    fail OSM::APIBadXMLError.new(model, xml) if placeholder_id.nil?

    # check if the placeholder ID has been given before and throw
    # an exception if it has - we can't create the same element twice.
    fail OSM::APIBadUserInput, 'Placeholder IDs must be unique for created elements.' if @ids[model_name.to_sym].include? placeholder_id

    # save placeholder => allocated ID map
    @ids[model_name.to_sym][placeholder_id] = new_id
  end

  ##
  # if any referenced nodes are placeholder IDs (i.e: are negative) then
  # this calling this method will fix them using the map from placeholders
  # to IDs +id_map+.
  def get_fixed_id(old_id, type)
    if old_id < 0
      new_id = @ids[type][old_id]
      # fail OSM::APIBadUserInput, "Placeholder #{type} not found for reference #{old_id} in #{self.class} #{self.id.nil? ? placeholder_id : self.id}" if new_id.nil?
      new_id
    else
      old_id
    end
  end
end

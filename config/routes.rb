# Portions Copyright (C) 2015 Intel Corporation

Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  get 'api/capabilities' => 'api#capabilities'

  get 'api/0.6/map' => 'api#map'

  get 'api/0.6/rerender' => 'api#rerender'
  get 'api/0.6/feeders' => 'api#feeders'

  post 'api/0.6/changeset/upload' => 'api#upload'

  get 'api/0.6/nodes' => 'api#list', type_name: 'nodes', model: PlanetOsmNode
  get 'api/0.6/ways' => 'api#list', type_name: 'ways', model: PlanetOsmWay
  get 'api/0.6/relations' => 'api#list', type_name: 'relations', model: PlanetOsmRel
end

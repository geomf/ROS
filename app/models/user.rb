class User < ActiveRecord::Base
  enum role: [ :admin, :user, :public ]
end

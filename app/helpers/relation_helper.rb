module RelationHelper

  def add_members_to_xml(el, members, type)
    members.each do |member|
      member_el = XML::Node.new "member"
      member_el["type"] = type
      member_el["role"] = ""
      member_el["ref"] = member.to_s
      el << member_el
    end
  end
end
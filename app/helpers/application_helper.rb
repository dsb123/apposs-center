module ApplicationHelper
  def err resource
    resource.errors.to_a.each{|msg| content_tag :li, msg}.join "\n"
  end
  
  def actions object
    raw (object.state_events - [:download,:fire,:continue,:error,:invoke,:ok,:force_stop,:clear]).collect{|event|
      link_to(
        I18n.t("activerecord.state_machines.events.#{event}"),
        eval("event_#{object.class.to_s.parameterize}_path(#{object.id})")+"?event=#{event}",
        :remote => true, :method => :put, :handle => true
      )
    }.join("\n")
  end
end

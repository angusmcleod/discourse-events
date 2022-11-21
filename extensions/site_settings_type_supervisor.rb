# frozen_string_literal: true

module SiteSettingsTypeSupervisorEventsExtension
  def type_hash(name)
    add_choices(name) if name == :top_menu
    super
  end

  def validate_value(name, type, val)
    add_choices(name) if name == :top_menu
    super
  end

  def add_choices(name)
    @choices[name].push("agenda") if @choices[name].exclude?("agenda")
    @choices[name].push("calendar") if @choices[name].exclude?("calendar")
  end
end

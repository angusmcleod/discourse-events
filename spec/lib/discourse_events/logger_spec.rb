# frozen_string_literal: true

require "rails_helper"

describe DiscourseEvents::Logger do
  subject { DiscourseEvents::Logger }

  it "creates logs" do
    subject.new(:sync).log(:info, "Test log")

    expect(DiscourseEvents::Log.exists?(level: "info", context: "sync", message: "Test log")).to eq(
      true,
    )
  end
end

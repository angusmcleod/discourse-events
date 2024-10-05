# frozen_string_literal: true
module DiscourseEvents
  class Publisher::Registration
    attr_accessor :uid,
                  :user_id,
                  :email,
                  :name,
                  :status

    def initialize(params = {})
      @uid = params[:uid]
      @user_id = params[:user_id]
      @email = params[:email]
      @name = params[:name]
      @status = params[:status]
    end

    def valid?
      @email.present?
    end
  end
end

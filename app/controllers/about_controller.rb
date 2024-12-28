class AboutController < ApplicationController
  before_action :authenticate_user

  protect_from_forgery

  def faq
  end

  def tos
  end

  def privacy
  end

  def support
  end
end

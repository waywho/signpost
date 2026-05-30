class Dashboard::TeamOverviewsController < ApplicationController
  def show
    @developers = Developer.by_name
  end
end

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Require authentication for all actions
  before_action :authenticate_user!
  before_action :check_page_permission

  # Helper method for views
  helper_method :page_allowed?

  private

  # Check if current user has permission to access the page
  def check_page_permission
    # Skip check for Devise controllers (login, registration, etc.)
    return if devise_controller?

    # Admin users have access to all pages
    return if current_user&.admin?

    page_key = determine_page_key
    return if page_key.nil?

    unless PagePermission.allowed?(page_key, current_user)
      flash[:alert] = '해당 페이지에 접근할 권한이 없습니다.'
      redirect_to root_path
    end
  end

  # Determine page key from controller/action
  def determine_page_key
    case controller_path
    when 'home'
      'home'
    when 'inventory'
      'inventory'
    when 'inventory/items'
      'inventory_items'
    when 'inventory/receipts'
      'inventory_receipts'
    when 'inventory/shipments'
      'inventory_shipments'
    when 'inventory/stocks'
      'inventory_stocks'
    when 'inventory/opened_items'
      'inventory_opened_items'
    when 'recipes'
      'recipes'
    when 'ingredients'
      'ingredients'
    when 'finished_products'
      'finished_products'
    when 'production'
      'production'
    when 'production/plans'
      'production_plans'
    when 'production/logs'
      'production_logs'
    when 'equipments'
      'equipments'
    when 'settings'
      'settings'
    else
      nil # Don't check permission for unlisted pages
    end
  end

  # Helper method for views to check permission
  def page_allowed?(page_key)
    PagePermission.allowed?(page_key, current_user)
  end
end

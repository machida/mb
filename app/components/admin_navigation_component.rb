class AdminNavigationComponent < ViewComponent::Base
  def initialize(current_admin:)
    @current_admin = current_admin
  end

  private

  attr_reader :current_admin

  def nav_items
    [
      {
        text: "全員",
        count: Admin.count,
        path: admin_admins_path,
        active: current_page?(admin_admins_path)
      },
      {
        text: "自分自身",
        count: nil,
        path: admin_admin_path(current_admin),
        active: current_page?(admin_admin_path(current_admin))
      }
    ]
  end

  def nav_class_for(item)
    "a--button is-md #{item[:active] ? 'is-warning' : 'is-border-secondary'}"
  end
end
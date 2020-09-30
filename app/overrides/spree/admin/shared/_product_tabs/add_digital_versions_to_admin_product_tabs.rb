Deface::Override.new(
  virtual_path: 'spree/admin/shared/_product_tabs',
  name: 'add_digital_versions_to_admin_product_tabs',
  insert_bottom: '[data-hook="admin_product_tabs"]',
  text: <<-HTML
          <li class="<%= 'active' if current == 'Digital Versions' %>">
<% if params[:from] == "shoutout" || params[:from] == "quickshout" %>
            <%= link_to_with_icon 'cloud', Spree.t(:upload_video, scope: 'digitals'), admin_product_digitals_path(@product), class: 'nav-link' %>
<%end%>
          </li>
        HTML
)

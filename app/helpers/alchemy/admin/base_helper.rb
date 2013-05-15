module Alchemy
  module Admin

    # This module contains helper methods for rendering overlay windows, toolbar buttons and confirmation windows.
    #
    # The most important helpers for module developers are:
    #
    # * {#toolbar}
    # * {#toolbar_button}
    # * {#link_to_overlay_window}
    # * {#link_to_confirmation_window}
    #
    module BaseHelper
      include Alchemy::BaseHelper

      # This helper renders the link to an overlay window.
      #
      # We use this for our fancy modal overlay windows in the Alchemy cockpit.
      #
      # == Example
      #
      #   <%= link_to_overlay_window('Edit', edit_product_path, {size: '200x300'}, {class: 'icon_button'}) %>
      #
      # @param [String] content
      #   The string inside the link tag
      # @param [String or Hash] url
      #   The url of the action displayed inside the overlay window.
      # @param [Hash] options
      #   options for the overlay window.
      # @param [Hash] html_options
      #   HTML options passed to the <tt>link_to</tt> helper
      #
      # @option options [String] :size
      #    String with format of "WidthxHeight". I.E. ("420x280")
      # @option options [String] :title
      #    Text for the overlay title bar.
      # @option options [Boolean] :overflow (false)
      #    Should the dialog have overlapping content. If not, it shows scrollbars. Good for select boxes.
      # @option options [Boolean] :resizable (false)
      #    Is the dialog window resizable?
      # @option options [Boolean] :modal (true)
      #    Show as modal window.
      # @option options [Boolean] :overflow (true)
      #    Should the window show overflowing content?
      #
      def link_to_overlay_window(content, url, options={}, html_options={})
        default_options = {
          :modal => true,
          :overflow => true,
          :resizable => false
        }
        options = default_options.merge(options)
        size = options.delete(:size).to_s.split('x')
        link_to(content, url,
          html_options.merge(
            'data-alchemy-overlay' => options.update(
              :width => size && size[0] ? size[0] : 'auto',
              :height => size && size[1] ? size[1] : 'auto',
            ).to_json
          )
        )
      end

      # (internal) Used for rendering the folder link in +Admin::Pages#index+ sitemap.
      def sitemapFolderLink(page)
        return '' if page.level == 1
        if page.folded?(current_user.id)
          css_class = 'folded'
          title = _t('Show childpages')
        else
          css_class = 'collapsed'
          title = _t('Hide childpages')
        end
        link_to(
          '',
          alchemy.fold_admin_page_path(page),
          :remote => true,
          :method => :post,
          :class => "page_folder #{css_class}",
          :title => title,
          :id => "fold_button_#{page.id}"
        )
      end

      # Used for language selector in Alchemy cockpit sitemap. So the user can select the language branche of the page.
      def language_codes_for_select
        configuration(:languages).collect { |language|
          language[:language_code]
        }
      end

      # Used for translations selector in Alchemy cockpit user settings.
      def translations_for_select
        Alchemy::I18n.available_locales.map do |locale|
          [_t(locale, :scope => :translations), locale]
        end
      end

      # Returns a javascript driven live filter for lists.
      #
      # The items must have a html +name+ attribute that holds the filterable value.
      #
      # == Example
      #
      # Given a list of items:
      #
      #   <%= js_filter_field('#products .product') %>
      #
      #   <ul id="products">
      #     <li class="product" name="kat litter">Kat Litter</li>
      #     <li class="product" name="milk">Milk</li>
      #   </ul>
      #
      # @param [String] items
      #   A jquery compatible selector string that represents the items to filter
      # @param [Hash] options
      #   HTML options passed to the input field
      #
      # @option options [String] :class ('js_filter_field')
      #   The css class of the <input> tag
      # @option options [String or Hash] :data ({'alchemy-list-filter' => items})
      #   A HTML data attribute that holds the jQuery selector that represents the list to be filtered
      #
      def js_filter_field(items, options = {})
        options = {
          class: 'js_filter_field',
          data: {'alchemy-list-filter' => items}
        }.merge(options)
        content_tag(:div, class: 'js_filter_field_box') do
          concat text_field_tag(nil, nil, options)
          concat content_tag('span', '', class: 'icon search')
          concat link_to('', '', class: 'js_filter_field_clear', title: _t(:click_to_show_all))
          concat content_tag(:label, _t(:search), for: options[:id])
        end
      end

      # Returns a link that opens a modal confirmation to delete window.
      #
      # === Example:
      #
      #   <%= link_to_confirmation_window('delete', 'Do you really want to delete this comment?', '/admin/comments/1') %>
      #
      # @param [String] link_string
      #   The content inside the <a> tag
      # @param [String] message
      #   The message that is displayed in the overlay window
      # @param [String] url
      #   The url that gets opened after confirmation (Note: This is an Ajax request with a method of DELETE!)
      # @param [Hash] html_options
      #   HTML options get passed to the link
      #
      # @option html_options [String] :title (_t(:please_confirm))
      #   The overlay title
      # @option html_options [String] :message (message)
      #   The message displayed in the overlay
      # @option html_options [String] :ok_label (_t("Yes"))
      #   The label for the ok button
      # @option html_options [String] :cancel_label (_t("No"))
      #   The label for the cancel button
      #
      def link_to_confirmation_window(link_string = "", message = "", url = "", html_options = {})
        link_to(link_string, url,
          html_options.merge(
            'data-alchemy-confirm-delete' => {
              :title => _t(:please_confirm),
              :message => message,
              :ok_label => _t("Yes"),
              :cancel_label => _t("No")
            }.to_json
          )
        )
      end

      # Returns a form and a button that opens a modal confirm window.
      #
      # After confirmation it proceeds to send the form's action.
      #
      # === Example:
      #
      #   <%= button_with_confirm('pay', '/admin/orders/1/pay', message: 'Do you really want to mark this order as payed?') %>
      #
      # @param [String] value
      #   The content inside the <tt><a></tt> tag
      # @param [String] url
      #   The url that gets opened after confirmation
      # @param [Hash] options
      #   Options for the Alchemy confirm overlay (see also +app/assets/javascripts/alchemy/alchemy.window.js#openConfirmWindow+)
      # @param [Hash] html_options
      #   HTML options that get passed to the +button_tag+ helper.
      #
      # @note The method option in the <tt>html_options</tt> hash gets passed to the <tt>form_tag</tt> helper!
      #
      def button_with_confirm(value = "", url = "", options = {}, html_options = {})
        options = {
          message: _t(:confirm_to_proceed),
          ok_label: _t("Yes"),
          title: _t(:please_confirm),
          cancel_label: _t("No")
        }.merge(options)
        form_tag url, {method: html_options.delete(:method)} do
          button_tag value, html_options.merge('data-alchemy-confirm' => options.to_json)
        end
      end

      # Returns an Array build for passing it to the options_for_select helper inside an essence editor partial.
      #
      # Useful for the <tt>select_values</tt> options from the {Alchemy::Admin::EssencesHelper#render_essence_editor} helpers.
      #
      # @option options [String or Page] :from_page (nil)
      #   Return only elements from this page. You can either pass a Page instance, or a page_layout name
      # @option options [Array or String] :elements_with_name (nil)
      #   Return only elements with this name(s).
      # @option options [String] :prompt (_t('Please choose'))
      #   Prompt inside the select tag.
      #
      def elements_for_essence_editor_select(options={})
        defaults = {
          :from_page => nil,
          :elements_with_name => nil,
          :prompt => _t('Please choose')
        }
        options = defaults.merge(options)
        if options[:from_page]
          page = options[:from_page].is_a?(String) ? Page.find_by_page_layout(options[:from_page]) : options[:from_page]
        end
        if page
          elements = options[:elements_with_name].blank? ? page.elements.published : page.elements.published.where(:name => options[:elements_with_name])
        else
          elements = options[:elements_with_name].blank? ? Element.published : Element.published.where(:name => options[:elements_with_name])
        end
        select_options = [[options[:prompt], ""]]
        elements.each do |e|
          select_options << [e.display_name_with_preview_text, e.id.to_s]
        end
        select_options
      end

      # Returns all public pages from current language as an option tags string suitable or the Rails +select_tag+ helper.
      #
      # @param [Array]
      #   A collection of pages so it only returns these pages and does not query the database.
      # @param [String]
      #   Pass a +Page#name+ or +Page#id+ as selected item to the +options_for_select+ helper.
      # @param [String]
      #   Used as prompt message in the select tag
      # @param [Symbol]
      #   Method that is called on the page object to get the value that is passed with the params of the form.
      #
      def pages_for_select(pages = nil, selected = nil, prompt = "", page_attribute = :id)
        result = [[prompt.blank? ? _t('Choose page') : prompt, ""]]
        if pages.blank?
          pages = Page.with_language(session[:language_id]).published.order(:lft)
          pages.each do |p|
            result << [("&nbsp;&nbsp;" * (p.level - 1) + p.name).html_safe, p.send(page_attribute).to_s]
          end
        else
          pages.each do |p|
            result << [p.name, p.send(page_attribute).to_s]
          end
        end
        options_for_select(result, selected.to_s)
      end

      def render_essence_selection_editor(element, content, select_options)
        if content.class == String
          content = element.contents.find_by_name(content)
        else
          content = element.contents[content - 1]
        end
        if content.essence.nil?
          return warning('Element', _t(:content_essence_not_found))
        end
        select_options = options_for_select(select_options, content.essence.content)
        select_tag(
          "contents[content_#{content.id}]",
          select_options,
          :class => 'alchemy_selectbox'
        )
      end

      # Renders the admin main navigation
      def admin_main_navigation
        entries = ""
        alchemy_modules.each do |alchemy_module|
          entries << alchemy_main_navigation_entry(alchemy_module)
        end
        entries.html_safe
      end

      # Renders one admin main navigation entry
      #
      # @param [Hash] alchemy_module
      #   The Hash representing a Alchemy module
      #
      def alchemy_main_navigation_entry(alchemy_module)
        render 'alchemy/admin/partials/main_navigation_entry', :alchemy_module => alchemy_module.stringify_keys, :navigation => alchemy_module['navigation'].stringify_keys
      end

      # Renders the subnavigation in the admin areas
      def admin_subnavigation
        alchemy_module = module_definition_for(:controller => params[:controller], :action => 'index')
        unless alchemy_module.nil?
          entries = alchemy_module["navigation"].stringify_keys['sub_navigation']
          render_admin_subnavigation(entries) unless entries.nil?
        else
          ""
        end
      end

      # Renders the Subnavigation for the admin interface.
      def render_admin_subnavigation(entries)
        render "alchemy/admin/partials/sub_navigation_tab", :entries => entries
      end

      # Used for checking the main navi permissions
      def navigate_module(navigation)
        [navigation["action"].to_sym, navigation["controller"].gsub(/^\//, '').gsub(/\//, '_').to_sym]
      end

      # Returns true if the current controller and action is in a modules navigation definition.
      def admin_mainnavi_active?(mainnav)
        mainnav.stringify_keys!
        subnavi = mainnav["sub_navigation"].map(&:stringify_keys) if mainnav["sub_navigation"]
        nested = mainnav["nested"].map(&:stringify_keys) if mainnav["nested"]
        if subnavi
          (!subnavi.detect { |subnav| subnav["controller"].gsub(/^\//, '') == params[:controller] && subnav["action"] == params[:action] }.blank?) ||
            (nested && !nested.detect { |n| n["controller"] == params[:controller] && n["action"] == params[:action] }.blank?)
        else
          mainnav["controller"] == params[:controller] && mainnav["action"] == params["action"]
        end
      end

      # Returns true if the subnavigation entry is in the current params
      def admin_sub_navigation_entry_active?(entry)
        params[:controller] == entry["controller"].gsub(/^\//, '') && (params[:action] == entry["action"] || entry["nested_actions"] && entry["nested_actions"].include?(params[:action]))
      end

      # Calls the url_for helper on either an alchemy module engine, or the app alchemy is mounted at.
      def url_for_module(alchemy_module)
        navigation = alchemy_module['navigation'].stringify_keys
        url_options = {
          :controller => navigation['controller'],
          :action => navigation['action']
        }
        if alchemy_module['engine_name']
          eval(alchemy_module['engine_name']).url_for(url_options)
        else
          # hack to prefix any controller-path with / so it doesn't refer to alchemy/...
          url_options[:controller] = url_options[:controller].gsub(/^([^\/])/, "/#{$1}")
          main_app.url_for(url_options)
        end
      end

      # Calls the url_for helper on either an alchemy module engine, or the app alchemy is mounted at.
      def url_for_module_sub_navigation(navigation)
        alchemy_module = module_definition_for(navigation)
        engine_name = alchemy_module['engine_name'] if alchemy_module
        navigation.stringify_keys!
        url_options = {
          :controller => navigation['controller'],
          :action => navigation['action']
        }
        if engine_name
          eval(engine_name).url_for(url_options)
        else
          main_app.url_for(url_options)
        end
      end

      def main_navigation_css_classes(navigation)
        ['main_navi_entry', admin_mainnavi_active?(navigation) ? 'active' : nil].compact.join(" ")
      end

      # (internal) Renders translated Module Names for html title element.
      def render_alchemy_title
        if content_for?(:title)
          title = content_for(:title)
        else
          title = _t(controller_name, :scope => :modules)
        end
        "Alchemy CMS - #{title}"
      end

      # (internal) Returns max image count as integer or nil. Used for the picture editor in element editor views.
      def max_image_count
        return nil if !@options
        if @options[:maximum_amount_of_images].blank?
          image_count = @options[:max_images]
        else
          image_count = @options[:maximum_amount_of_images]
        end
        if image_count.blank?
          nil
        else
          image_count.to_i
        end
      end

      # (internal) Renders a select tag for all items in the clipboard
      def clipboard_select_tag(items, html_options = {})
        options = [[_t('Please choose'), ""]]
        items.each do |item|
          options << [item.class.to_s == 'Alchemy::Element' ? item.display_name_with_preview_text : item.name, item.id]
        end
        select_tag(
          'paste_from_clipboard',
          !@page.new_record? && @page.can_have_cells? ? grouped_elements_for_select(items, :id) : options_for_select(options),
          {
            :class => [html_options[:class], 'alchemy_selectbox'].join(' '),
            :style => html_options[:style]
          }
        )
      end

      # Renders a toolbar button for the Alchemy toolbar
      #
      # @option options [String] :icon
      #   Icon class. See +app/assets/stylesheets/alchemy/icons.css.sccs+ for available icons, or make your own.
      # @option options [String] :label
      #   Text for button label.
      # @option options [String] :url
      #   Url for link.
      # @option options [String] :title
      #   Text for title tag.
      # @option options [String] :hotkey
      #   Keyboard shortcut for this button. I.E +alt-n+
      # @option options [Boolean] :overlay (true)
      #   Open the link in a modal overlay window.
      # @option options [Hash] :overlay_options
      #   Overlay options. See link_to_overlay_window helper.
      # @option options [Array] :if_permitted_to ([:action, :controller])
      #   Check permission for button. Exactly how you defined the permission in your +authorization_rules.rb+. Defaults to controller and action from button url.
      # @option options [Boolean] :skip_permission_check (false)
      #   Skip the permission check. NOT RECOMMENDED!
      # @option options [Boolean] :loading_indicator (true)
      #   Shows the please wait overlay while loading. Only for buttons not opening an overlay window.
      #
      def toolbar_button(options = {})
        options.symbolize_keys!
        defaults = {
          :overlay => true,
          :skip_permission_check => false,
          :active => false,
          :link_options => {},
          :overlay_options => {},
          :loading_indicator => true
        }
        options = defaults.merge(options)
        button = content_tag('div', :class => 'button_with_label' + (options[:active] ? ' active' : '')) do
          link = if options[:overlay]
            link_to_overlay_window(
              render_icon(options[:icon]),
              options[:url],
              options[:overlay_options],
              {
                :class => 'icon_button',
                :title => options[:title],
                'data-alchemy-hotkey' => options[:hotkey]
              }.merge(options[:link_options])
            )
          else
            link_to options[:url], {:class => ("icon_button#{options[:loading_indicator] ? ' please_wait' : nil}"), :title => options[:title], 'data-alchemy-hotkey' => options[:hotkey]}.merge(options[:link_options]) do
              render_icon(options[:icon])
            end
          end
          link += content_tag('label', options[:label])
        end
        if options[:skip_permission_check]
          return button
        else
          if options[:if_permitted_to].blank?
            action_controller = options[:url].gsub(/^\//, '').split('/')
            options[:if_permitted_to] = [action_controller.last.to_sym, action_controller[0..action_controller.length-2].join('_').to_sym]
          end
          if permitted_to?(*options[:if_permitted_to])
            return button
          else
            return ""
          end
        end
      end

      # Renders the toolbar shown on top of the records.
      #
      # == Example
      #
      #   <% label_title = _t("Create #{resource_name}", default: _t('Create')) %>
      #   <% toolbar(
      #     buttons: [
      #       {
      #         icon: 'create',
      #         label: label_title,
      #         url: new_resource_path,
      #         title: label_title,
      #         hotkey: 'alt-n',
      #         overlay_options: {
      #           title: label_title,
      #           size: "430x400"
      #         },
      #         if_permitted_to: [:new, resource_permission_scope]
      #       }
      #     ]
      #   ) %>
      #
      # @option options [Array] :buttons ([])
      #   Pass an Array with button options. They will be passed to {#toolbar_button} helper.
      # @option options [Boolean] :search (true)
      #   Show searchfield.
      #
      def toolbar(options = {})
        defaults = {
          :buttons => [],
          :search => true
        }
        options = defaults.merge(options)
        content_for(:toolbar) do
          content = <<-CONTENT
#{options[:buttons].map { |button_options| toolbar_button(button_options) }.join()}
          #{render('alchemy/admin/partials/search_form', :url => options[:search_url]) if options[:search]}
          CONTENT
          content.html_safe
        end
      end

      # Renders the row for a resource record in the resources table.
      #
      # This helper has a nice fallback. If you create a partial for your record then this partial will be rendered.
      #
      # Otherwise the default +app/views/alchemy/admin/resources/_resource.html.erb+ partial gets rendered.
      #
      # == Example
      #
      # For a resource named +Comment+ you can create a partial named +_comment.html.erb+
      #
      #   # app/views/admin/comments/_comment.html.erb
      #   <tr>
      #     <td><%= comment.title %></td>
      #     <td><%= comment.body %></td>
      #   </tr>
      #
      # NOTE: Alchemy gives you a local variable named like your resource
      #
      def render_resources
        render :partial => resource_name, :collection => resources_instance_variable
      rescue ActionView::MissingTemplate
        render :partial => 'resource', :collection => resources_instance_variable
      end

      # (internal) Used by upload form
      def new_asset_path_with_session_information(asset_type)
        session_key = Rails.application.config.session_options[:key]
        if asset_type == "picture"
          alchemy.admin_pictures_path(session_key => cookies[session_key], request_forgery_protection_token => form_authenticity_token, :format => :js)
        elsif asset_type == "attachment"
          alchemy.admin_attachments_path(session_key => cookies[session_key], request_forgery_protection_token => form_authenticity_token, :format => :js)
        end
      end

      # Renders a textfield ready to display a datepicker
      #
      # Uses a HTML5 <tt><input type="date"></tt> field.
      #
      # === Example
      #
      #   <%= alchemy_datepicker(@person, :birthday) %>
      #
      # @param [ActiveModel::Base] object
      #   An instance of a model
      # @param [String or Symbol] method
      #   The attribute method to be called for the date value
      #
      # @option html_options [String] :type ('date')
      #   The type of text field
      # @option html_options [String] :class ('thin_border date')
      #   CSS classes of the input field
      # @option html_options [String] :value (object.send(method.to_sym).nil? ? nil : l(object.send(method.to_sym), :format => :datepicker))
      #   The value the input displays
      #
      def alchemy_datepicker(object, method, html_options={})
        text_field(object.class.name.underscore.to_sym, method.to_sym, {
          :type => 'date',
          :class => 'thin_border date',
          :value => object.send(method.to_sym).nil? ? nil : l(object.send(method.to_sym), :format => :datepicker)
        }.merge(html_options))
      end

      # Merges the params-hash with the given hash
      def merge_params(p={})
        params.merge(p).delete_if { |k, v| v.blank? }
      end

      # Deletes one or several params from the params-hash and merges some new params in
      def merge_params_without(excludes, p={})
        current_params = params.clone.symbolize_keys
        if excludes.is_a?(Array)
          excludes.map { |i| current_params.delete(i.to_sym) }
        else
          current_params.delete(excludes.to_sym)
        end
        current_params.merge(p).delete_if { |k, v| v.blank? }
      end

      # Deletes all params from the params-hash except the given ones and merges some new params in
      def merge_params_only(includes, p={})
        current_params = params.clone.symbolize_keys
        if includes.is_a?(Array)
          symbolized_includes = includes.map(&:to_sym)
          current_params.delete_if { |k, v| !symbolized_includes.include?(k) }
        else
          current_params.delete_if { |k, v| k != includes.to_sym }
        end
        current_params.merge(p).delete_if { |k, v| v.blank? }
      end

      def render_hint_for(element)
        return unless element.has_hint?
        link_to '#', :class => 'hint' do
          render_icon(:hint) + content_tag(:span, element.hint.html_safe, :class => 'bubble')
        end
      end

      # Appends the current controller and action to body as css class.
      def body_class
        "#{controller_name} #{action_name}"
      end

    end
  end
end
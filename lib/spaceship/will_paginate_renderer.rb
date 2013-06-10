# coding: UTF-8

class Spaceship::WillPaginateRenderer < WillPaginate::ActionView::LinkRenderer  
  def url(page)
    @base_url_params ||= begin
      url_params = merge_get_params(default_url_params)
      merge_optional_params(url_params)
    end

    url_params = @base_url_params.dup
    url_params.delete(:slide)
    
    add_current_page_param(url_params, page)

    @template.url_for(url_params)
  end  
  
  def to_html
    html = '<ul>'
    link_attributes = @options[:link_attributes] || {}
    html += pagination.map do |item|
      item.is_a?(Fixnum) ?
        page_number(item, link_attributes) :
        send(item, link_attributes)
    end.join(@options[:link_separator])
    html += '</ul>'

    @options[:container] ? html_container(html) : html    
  end
  
protected  
  def page_number(page, link_attributes = {})
    if page == current_page
      tag(:li, tag(:span, page), :class => 'active')
    else
      tag(:li, link(page, page, link_attributes.merge(:rel => rel_value(page))))
    end
  end
  
  def previous_page(link_attributes = {})
    num = @collection.current_page > 1 && @collection.current_page - 1
    if num
      tag(:li, link(@options[:previous_label], num, link_attributes), :class => 'prev')
    else
      tag(:li, tag(:span, @options[:previous_label]), :class => 'prev disabled')
    end
  end
  
  def next_page(link_attributes = {})
    num = @collection.current_page < @collection.total_pages && @collection.current_page + 1
    if num
      tag(:li, link(@options[:next_label], num, link_attributes), :class => 'next')
    else
      tag(:li, tag(:span, @options[:next_label]), :class => 'next disabled')
    end
  end

  def gap(link_attributes = {})
    text = @template.will_paginate_translate(:page_gap) { '&hellip;' }
    tag(:li, link(text, '#', link_attributes))
  end
end
# -*- coding: utf-8 -*-

include Helpers::ModuleHelper

def init
  sections :header,
    :box_info,
    T('docstring'),
    :modules,
    :classes,
    :constant_summary, [T('docstring')],
    :inherited_constants,
    :class_method_summary, [:item_summary],
    :instance_method_summary, [:item_summary],
    :inherited_methods,
    :methodmissing, [T('method_details')],
    :class_methods, [T('method_details')],
    :instance_methods, [T('method_details')]
end

def modules
  @modules = run_verifier(object.children.select{ |e| e.type == :module }.sort_by{ |e| e.name.to_s })
  erb(:modules) unless @modules.empty?
end

def classes
  @classes = run_verifier(object.children.select{ |e| e.type == :class }.sort_by{ |e| e.name.to_s })
  erb(:classes) unless @classes.empty?
end

def constant_summary
  erb(:constant_summary) unless constant_list.empty?
end

def inherited_constants
  @inherited_constants = inherited_x{ |e| e.constants(:included => false, :inherited => false) }
  erb(:inherited_constants) unless @inherited_constants.empty?
end

def inherited_x
  object.inheritance_tree(true)[1..-1].
    reject{ |e| YARD::CodeObjects::Proxy === e }.
    map{ |e| [e, run_verifier(yield(e)).select{ |m| object.child(:scope => :class, :name => m.name).nil? }] }.
    reject{ |_, e| e.empty? }
end

def class_method_summary
  erb(:class_method_summary) unless class_method_list.empty?
end

def instance_method_summary
  erb(:instance_method_summary) unless instance_method_list.empty?
end

def inherited_methods
  @inherited_methods ||= inherited_x{ |e| e.meths(:included => false, :inherited => false) }
  erb(:inherited_methods) unless @inherited_methods.empty?
end

def methodmissing
  return unless @mm = object.meths(:inherited => true, :included => true).find{ |e| e.name == :method_missing and e.scope == :instance }
  erb(:methodmissing)
end

def class_methods
  erb(:class_methods) unless non_special_class_method_list.empty?
end

def instance_methods
  erb(:instance_methods) unless non_special_instance_method_list.empty?
end

def constant_list
  @constants ||= run_verifier(object.constants(:included => false, :inherited => false) + object.cvars)
end

def class_method_list
  @class_methods ||= scoped_method_listing(:class)
end

def instance_method_list
  @instance_methods ||= scoped_method_listing(:instance)
end

def non_special_class_method_list
  @non_special_class_methods ||= scoped_method_listing(:class, false)
end

def non_special_instance_method_list
  @non_special_instance_methods ||= scoped_method_listing(:instance, false)
end

def scoped_method_listing(scope, include_specials = true)
  method_listing(include_specials).select{ |e| e.scope == scope }
end

def method_listing(include_specials = true)
  return @smeths ||= method_listing.reject{ |o| special_method?(o) } unless include_specials
  @meths ||= sort_listing(run_verifier(object.meths(:inherited => false, :included => false)))
end

def special_method?(method)
  method.constructor? or method.name(true) == '#method_missing'
end

def sort_listing(list)
  list.sort_by{ |e| [e.scope.to_s, e.name.to_s.downcase] }
end

def docstring_full(obj)
  docstring = (obj.docstring.empty? and obj.tags(:overload).size > 0) ? obj.tag(:overload).docstring : obj.docstring
  if docstring.summary.empty? and obj.tags(:return).size == 1 and obj.tag(:return).text
    # TODO: Perhaps add a “Returns ” prefix and add a “.” suffix, if missing.
    docstring = Docstring.new(obj.tag(:return).text)
  end
  docstring
end

def docstring_summary(obj)
  docstring_full(obj).summary
end

# TODO: Re-enable support for this.  Groups will have to be per scope.
def groups(list)
  if groups_data = object.groups
    others = list.select {|m| !m.group }
    groups_data.each do |name|
      items = list.select {|m| m.group == name }
      yield(items, name) unless items.empty?
    end
  else
    others = []
    group_data = {}
    list.each do |meth|
      if meth.group
        (group_data[meth.group] ||= []) << meth
      else
        others << meth
      end
    end
    group_data.each {|group, items| yield(items, group) unless items.empty? }
  end

  scopes(others){ |items, scope| yield items, scope }
end

def scopes(list)
  [:class, :instance].each do |scope|
    items = list.select{ |m| m.scope == scope }
    yield items, scope unless items.empty?
  end
end

def mixed_into(object)
  unless globals.mixed_into
    globals.mixed_into = {}
    run_verifier(Registry.all(:class, :module)).each do |e|
      e.mixins.each do |m|
        (globals.mixed_into[m.path] ||= []) << e
      end
    end
  end
  globals.mixed_into[object.path] || []
end

def overload_summary_signature(method)
  overload = link = convert_method_to_overload(method)
  # TODO: Deal with overload.visibility?
  '%s%s%s' % [link_url(url_for(link.respond_to?(:object) ? link.object : link),
                       h(link.name),
                       :title => h(YARD::CodeObjects::MethodObject === link ? link.name(true) : link.name)),
              format_args(overload),
              now_format_block(overload)]
end

def summary_signature(method)
  if method.respond_to? :is_alias? and method.is_alias?
    if method.alias_for
      link, overload = method, convert_method_to_overload(method.alias_for)
    else
      link = overload = method
    end
  else
    overload = link = convert_method_to_overload(method)
  end
  # TODO: Deal with overload.visibility?
  '%s%s%s' % [link_url(url_for(link.respond_to?(:object) ? link.object : link),
                       h(link.name),
                       :title => h(YARD::CodeObjects::MethodObject === link ? link.name(true) : link.name)),
              overloaded_format_args(overload),
              overloaded_format_block(overload)]
end

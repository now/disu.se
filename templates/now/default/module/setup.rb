# -*- coding: utf-8 -*-

# TODO: Remove dependency on prune_method_listing in class or at least move
# this include there.
include Helpers::ModuleHelper

def init
  sections :header,
    :box_info,
    T('docstring'),
    :modules,
    :classes,
    :constant_summary, [T('docstring')],
    :class_method_summary, [:item_summary],
    :instance_method_summary, [:item_summary],
    :methodmissing, [T('method_details')],
    :class_methods, [T('method_details')],
    :instance_methods, [T('method_details')]
end

def modules
  @modules = children_of_type(:module)
  erb(:modules) unless @modules.empty?
end

def classes
  @classes = children_of_type(:class)
  erb(:classes) unless @classes.empty?
end

def children_of_type(type)
  run_verifier(object.children.select{ |e| e.type == type }.sort_by{ |e| e.name.to_s })
end

def constant_summary
  erb(:constant_summary) unless constant_list.empty? and inherited_constant_list.empty?
end

def inherited_constant_list
  @inherited_constants ||= inherited_x{ |e|
    e.constants(:included => false, :inherited => false).
      select{ |c| object.child(:type => :constant, :name => c.name).nil? }
  }
end

def inherited_x
  object.inheritance_tree(true)[1..-1].
    reject{ |e| YARD::CodeObjects::Proxy === e }.
    map{ |e| [e, run_verifier(yield(e)).sort_by{ |x| x.name.to_s }] }.
    reject{ |_, e| e.empty? }
end

def class_method_summary
  erb(:class_method_summary) unless class_method_list.empty? and inherited_class_method_list.empty?
end

def instance_method_summary
  erb(:instance_method_summary) unless instance_method_list.empty? and inherited_instance_method_list.empty?
end

def inherited_class_method_list
  @inherited_class_methods ||= scoped_inherited_methods(:class)
end

def inherited_instance_method_list
  @inherited_instance_methods ||= scoped_inherited_methods(:instance)
end

def scoped_inherited_methods(scope)
  inherited_x{ |e|
    e.meths(:included => false, :inherited => false, :scope => scope).
      select{ |m| object.child(:scope => scope, :name => m.name).nil? }.
      reject{ |m| special_method?(m) }
  }
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
  return @smeths ||= method_listing.reject{ |m| special_method?(m) } unless include_specials
  @meths ||= run_verifier(object.meths(:inherited => false, :included => false)).
    sort_by{ |e| [e.scope.to_s, e.name.to_s.downcase] }.
    map{ |e| inline_overloads(e) }.
    flatten
end

def special_method?(method)
  method.constructor? or method.name(true) == '#method_missing'
end

def inline_overloads(method)
  return method if method.tags(:overload).empty?
  method.tags(:overload).map{ |e|
    n = method.dup
    n.signature = e.signature
    n.parameters = e.parameters
    n.docstring = e.docstring
    n
  }
end

def docstring_summary(obj)
  # TODO: Perhaps add a “Returns ” prefix and add a “.” suffix, if missing.
  return Docstring.new(obj.tag(:return).text).summary if
    obj.docstring.summary.empty? and
    obj.tags(:return).size == 1 and
    obj.tag(:return).text
  obj.docstring.summary
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

def summary_signature(method)
  target = (method.respond_to? :is_alias? and method.is_alias? and method.alias_for) ?
    method.alias_for :
    method
  # TODO: Deal with method.visibility?
  '%s%s%s' %
    [link_url(url_for(method), h(method.name), :title => h(method.name(true))),
     format_args(target),
     format_block(target)]
end

# -*- coding: utf-8 -*-

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
  run_verifier(object.children.select{ |e| e.type == type }).sort_by{ |e| e.name.to_s }
end

def constant_summary
  @constants = run_verifier(object.constants(:inherited => false, :included => false) + object.cvars)
  @inherited_constants = inherited_x{ |e|
    e.constants(:inherited => false, :included => false).
      select{ |c| object.child(:type => :constant, :name => c.name).nil? }
  }
  erb(:constant_summary) unless @constants.empty? and @inherited_constants.empty?
end

def inherited_x
  object.inheritance_tree(true)[1..-1].
    reject{ |e| YARD::CodeObjects::Proxy === e }.
    map{ |e| [e, run_verifier(yield(e)).sort_by{ |x| x.name.to_s }] }.
    reject{ |_, e| e.empty? }
end

def class_method_summary
  @class_methods = scoped_methods(:class).sort_by{ |e| e.name.to_s }
  @inherited_class_methods = scoped_inherited_methods(:class)
  erb(:class_method_summary) unless @class_methods.empty? and @inherited_class_methods.empty?
end

def instance_method_summary
  @instance_methods = scoped_methods(:instance).sort_by{ |e| e.name.to_s }
  @inherited_instance_methods = scoped_inherited_methods(:instance)
  erb(:instance_method_summary) unless @instance_methods.empty? and @inherited_instance_methods.empty?
end

def scoped_inherited_methods(scope)
  inherited_x{ |e|
    e.meths(:inherited => false, :included => false, :scope => scope).
      select{ |m| object.child(:scope => scope, :name => m.name).nil? }.
      reject{ |m| special_method?(m) }
  }
end

def methodmissing
  return unless @mm = object.meths(:inherited => true, :included => true).find{ |e| e.name(true) == '#method_missing' }
  erb(:methodmissing)
end

def class_methods
  @non_special_class_methods = scoped_methods(:class, false)
  erb(:class_methods) unless @non_special_class_methods.empty?
end

def instance_methods
  @non_special_instance_methods = scoped_methods(:instance, false)
  erb(:instance_methods) unless @non_special_instance_methods.empty?
end

def scoped_methods(scope, include_specials = true)
  run_verifier(object.meths(:inherited => false, :included => false, :scope => scope)).
    map{ |e| inline_overloads(e) }.
    flatten.
    select{ |m| include_specials or not special_method? m }
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

def mixed_into(object)
  (globals.mixed_into ||= run_verifier(Registry.all(:class, :module)).reduce({}){ |h, e|
     e.mixins.each do |m|
       (h[m.path] ||= []) << e
     end
     h
   })[object.path] || []
end

def now_format_object_title(object)
  '%s<sub class="type">%s</sub>' % [object.path, format_object_type(object)]
end

def summary_signature(method)
  target = (method.respond_to? :is_alias? and method.is_alias? and method.alias_for) ?
    method.alias_for :
    method
  # TODO: Deal with method.visibility?
  '%s%s%s' %
    [link_url(url_for(method), method_name_h(method.name), :title => h(method.name(true))),
     now_format_args(target, false),
     now_format_block(target, false)]
end

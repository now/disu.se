# -*- coding: utf-8 -*-

def init
  sections :header,
    T('docstring'),
    :box_info,
    :modules,
    :classes,
    :constant_summary, [T('docstring')],
    :methodmissing, [T('method_details')],
    :class_methods, [T('method_details')],
    :instance_methods, [T('method_details')]
end

def box_info
  @ancestors = object.inheritance_tree(true)[1..-1]
  @inherited_class_methods = scoped_inherited_methods(:class)
  @inherited_instance_methods = scoped_inherited_methods(:instance)
  erb(:box_info) unless @ancestors.empty? and
    not CodeObjects::ClassObject === object and
    object.mixins(:class).empty? and
    mixed_into(object).empty?
end

def scoped_inherited_methods(scope)
  inherited_x{ |e|
    e.meths(:inherited => false, :included => false, :scope => scope).
      select{ |m| object.child(:scope => scope, :name => m.name).nil? }.
      reject{ |m| special_method?(m) }
  }
end

def inherited_x
  object.inheritance_tree(true)[1..-1].
    reject{ |e| YARD::CodeObjects::Proxy === e }.
    map{ |e| [e, run_verifier(yield(e)).sort_by{ |x| x.name.to_s }] }.
    reject{ |_, e| e.empty? }
end

def mixed_into(object)
  (globals.mixed_into ||= run_verifier(Registry.all(:class, :module)).reduce({}){ |h, e|
     e.mixins.each do |m|
       (h[m.path] ||= []) << e
     end
     h
   })[object.path] || []
end

def modules
  children(:module)
end

def classes
  children(:classes)
end

def children(type)
  @type = type
  @children = run_verifier(object.children.select{ |e| e.type == type }).sort_by{ |e| e.name.to_s }
  erb(:children) unless @children.empty?
end

def constant_summary
  @constants = run_verifier(object.constants(:inherited => false, :included => false) + object.cvars)
  @inherited_constants = inherited_x{ |e|
    e.constants(:inherited => false, :included => false).
      select{ |c| object.child(:type => :constant, :name => c.name).nil? }
  }
  erb(:constant_summary) unless @constants.empty? and @inherited_constants.empty?
end

def methodmissing
  return unless @mm = object.meths(:inherited => true, :included => true).find{ |e| e.name(true) == '#method_missing' }
  erb(:methodmissing)
end

def class_methods
  methods(:class)
end

def instance_methods
  methods(:instance)
end

def methods(scope)
  @scope = scope
  @methods = run_verifier(object.meths(:inherited => false, :included => false, :scope => scope)).
    map{ |e| inline_overloads(e) }.
    flatten.
    reject{ |m| special_method? m }
  erb(:methods) unless @methods.empty?
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

def now_format_object_title(object)
  '%s<sub class="type">%s</sub>' % [object.path, format_object_type(object)]
end

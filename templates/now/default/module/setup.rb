# -*- coding: utf-8 -*-

def init
  sections :header,
    T('docstring'),
    :box_info, [:namespace, :ancestors, :extends, :includers],
    :modules,
    :classes,
    :constant_summary, [T('docstring')],
    :methodmissing, [T('method_details')],
    :class_methods, [T('method_details')],
    :instance_methods, [T('method_details')]
end

def namespace
  erb(:namespace) unless object.root?
end

def ancestors
  @ancestors = object.inheritance_tree[1..-1]
  erb(:ancestors) unless @ancestors.empty? and not CodeObjects::ClassObject === object
end

def methods_inherited_from(ancestor, scope)
  return [] if YARD::CodeObjects::Proxy === ancestor
  @inherited_methods ||= { :class => {}, :instance => {} }
  run_verifier(ancestor.meths(:inherited => false, :included => false, :scope => scope).
    reject{ |e| object.child(:scope => scope, :name => e.name) or special_method? e or @inherited_methods[scope].include? e.name }).
    tap{ |es| es.each{ |e| @inherited_methods[scope][e.name] = true } }.
    sort_by{ |e| e.name.to_s }
end

def extends
  erb(:extends) unless object.mixins(:class).empty?
end

def includers
  erb(:includers) unless mixed_into(object).empty?
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

def inherited_x
  object.inheritance_tree(true)[1..-1].
    reject{ |e| YARD::CodeObjects::Proxy === e }.
    map{ |e| [e, run_verifier(yield(e)).sort_by{ |x| x.name.to_s }] }.
    reject{ |_, e| e.empty? }
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
    reject{ |m| special_method? m }.
    map{ |e| inline_overloads(e) }.
    flatten
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

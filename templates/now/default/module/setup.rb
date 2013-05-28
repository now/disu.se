# -*- coding: utf-8 -*-

def init
  sections :header,
    :box_info, [:namespace, :ancestors, :extends, :includers],
    T('docstring'),
    :childrn,
    :class_methods, [T('method_details')],
    :methodmissing, [T('method_details')],
    :instance_methods, [T('method_details')]
end

def namespace
  erb(:namespace) unless object.root?
end

def ancestors
  @ancestors = object.inheritance_tree(true)[1..-1].reverse.reduce([[], {}]){ |v, e| v.last[e.path] ||= v.first << e; v }.first.reverse
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
  erb(:includers) unless (@includers = mixed_into(object)).empty?
end

def mixed_into(object)
  fetch_shortest_unique_suffixes((globals.mixed_into ||= run_verifier(Registry.all(:class, :module)).reduce({}){ |h, e|
                                    e.mixins.each do |m|
                                      (h[m.path] ||= []) << e
                                    end
                                    h
                                  }), object)
end

def childrn
  @children =
    run_verifier(object.children.select{ |e| e.type == :module or e.type == :class } +
                 object.constants(:inherited => false, :included => false) + object.cvars).
    sort_by{ |e| e.name.to_s }
  erb(:children) unless @children.empty?
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
    flatten.
    partition{ |e| e.is_explicit? }.
    flatten
  erb(:methods) unless @methods.empty?
end

def special_method?(method)
  method.constructor? or method.name(true) == '#method_missing'
end

# -*- coding: utf-8 -*-

include T('default/module')
include Helpers::ModuleHelper

def init
  super
  sections.find{ |e| e.name == :box_info } << :subclasses
#  sections.place(:constructor_details, [T('method_details')]).before(:methodmissing)
end

def constructor_details
  # TODO: Why not use #constructor? here?
  return unless @constructor = object.meths(:inherited => true, :included => true).find{ |e| e.name == :initialize }
  erb(:constructor_details) unless prune_method_listing([@constructor]).empty?
end

def subclasses
  return if object.path == 'Object'
  @subclasses = (globals.subclasses ||= run_verifier(Registry.all(:class)).reduce({}){ |h, e|
                   (h[e.superclass.path] ||= []) << e if e.superclass
                   h
                 }).fetch(object.path, []).sort_by{ |e| e.path }.map{ |e|
    [object.namespace ? object.relative_path(e) : e.path, e]
  }
  erb(:subclasses) unless @subclasses.empty?
end

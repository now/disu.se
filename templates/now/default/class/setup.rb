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
   @constructors = inline_overloads(object.meths(:inherited => true, :included => true).find{ |e| e.name == :initialize })
   return if @constructors.empty?
   return if prune_method_listing(@constructors).empty?
   erb(:constructor_details) unless @constructors.all?{ |e| e.docstring.strip.empty? and e.tags.reject{ |e| e.tag_name.to_s == 'return' }.empty? }
end

def subclasses
  return if object.path == 'Object'
  @subclasses =
    fetch_shortest_unique_suffixes((globals.subclasses ||= run_verifier(Registry.all(:class)).reduce({}){ |h, e|
                                      (h[e.superclass.path] ||= []) << e if e.superclass
                                      h
                                    }), object)
  erb(:subclasses) unless @subclasses.empty?
end

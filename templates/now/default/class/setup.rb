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
  return if prune_method_listing([@constructor]).empty?
  erb(:constructor_details) unless @constructor.docstring.strip.empty? and @constructor.tags.reject{ |e| e.tag_name == :return }.empty?
end

def subclasses
  return if object.path == 'Object'
  @subclasses =
    shortest_unique_suffixes((globals.subclasses ||= run_verifier(Registry.all(:class)).reduce({}){ |h, e|
                                (h[e.superclass.path] ||= []) << e if e.superclass
                                h
                              }).fetch(object.path, []).
                             map{ |e| [e.path.split('::'), e] }).
    map{ |p, e| r, s = object.relative_path(e), p.join('::'); [r.length < s.length ? r : s, e] }.
    sort_by{ |_, e| e.path }
  erb(:subclasses) unless @subclasses.empty?
end

def shortest_unique_suffixes(array)
  done, remaining = array.partition{ |e| e.first.empty? }
  return done if remaining.empty?
  same, different = remaining.partition{ |e| e.first.last == remaining.first.first.last }
  done.
    concat(same.size > 1 ?
             shortest_unique_suffixes(same.map{ |e| [e.first[0..-2], e.last] }).
               map.with_index{ |e, i| e.first.push(same[i].first.last); e } :
             [[[same.first.first.last], same.first.last]]).
    concat(shortest_unique_suffixes(different))
end

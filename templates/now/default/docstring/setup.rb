# -*- coding: utf-8 -*-

def init
  return if object.docstring.blank? and not((object.respond_to? :is_alias? and object.is_alias?) or object.has_tag? :api)
  sections :text, T('tags')
end

def docstring_text
  return object.tag(:return).text if
    object.docstring.strip.empty? and
    object.tags(:return).size == 1 and
    object.tag(:return).text
  object.docstring
end
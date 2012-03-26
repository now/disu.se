# -*- coding: utf-8 -*-

def init
  return if object.docstring.blank? and not((object.respond_to? :is_alias? and object.is_alias?) or object.has_tag? :api)
  sections :text, T('tags')
end

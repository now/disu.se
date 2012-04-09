# -*- coding: utf-8 -*-

def init
  return if object.docstring.blank? and not((object.respond_to? :is_alias? and object.is_alias?) or object.has_tag? :api)
  sections :text, T('tags')
end

def link_to_alias(object)
  target = object.namespace.aliases[object]
  method = object.namespace.child(target)
  method ? linkify(method, method_name_h('#%s' % method.name)) : method_name_h('#%s' % target)
end

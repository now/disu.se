# -*- coding: utf-8 -*-

def init
  return if object.docstring.blank? and not((object.respond_to? :is_alias? and object.is_alias?) or object.has_tag? :api)
  sections :text, T('tags')
end

def link_to_alias(object)
  target = object.namespace.aliases[object]
  method = object.namespace.child(target)
  if i = object[:overload_index] and overload = method.tags(:overload)[i]
    overload[:overload_index] = i
    method = overload
  end
  method ? linkify(method, method_name_h('%s%s' % [method.sep, method.name])) : method_name_h('%s%s' % [object.sep, target])
end

def text_from_return(object)
  return '' unless return_used_for_docstring? object
  return '' if object.respond_to? :constructor? and object.constructor?
  text = object.tag(:return).text
  '%s %s%s%s' % [(object.respond_to? :writer? and object.writer?) ?
                 'Sets and returns' : 'Returns', text[0..0].downcase,
                 text[1..-1], text.end_with?('.') ? '' : '.']
end


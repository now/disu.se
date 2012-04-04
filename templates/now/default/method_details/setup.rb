# -*- coding: utf-8 -*-

def init
  sections :method_signature, [T('docstring')]
end

def title_signature(method)
  types = title_signature_types(method)
  '%s%s%s%s%s' % [method_name_h(method.name),
                  now_format_args(method),
                  now_format_block(method),
                  types.empty? ? '' : '<sub class="type">%s</sub>' % types,
                  method.visibility != :public ? '<sub class="visibility">%s</sub>' % method.visibility : '']
end

def title_signature_types(method)
  # TODO: Why is this needed?
  method = method.object if method.respond_to?(:object) and not method.has_tag?(:return)
  return h(options[:default_return]) unless method.tag(:return) and method.tag(:return).types
  types = method.tags(:return).map{ |e| e.types or [] }.flatten.uniq
  if types.size == 2 and types.last == 'nil'
    '%s<sup>?</sup>' % title_signature_format_types(types.first)
  elsif types.size == 2 and types.last =~ /\A(?:Array)?<#{Regexp.quote(types.first)}>\z/
    '%s<sup>+</sup>' % title_signature_format_types(types.first)
  elsif types.size > 2
    # TODO: Why?
    '%s, …' % title_signature_format_types(types.first)
  elsif types == ['void'] and options[:hide_void_return]
    ''
  else
    title_signature_format_types(*types)
  end
end

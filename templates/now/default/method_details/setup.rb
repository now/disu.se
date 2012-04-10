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

def now_format_args(method, show_types = !params_documented?(method))
  return '' if method.parameters.nil?
  parameters = (method.has_tag? :yield or method.has_tag? :yieldparam) ?
    method.parameters.reject{ |e| e.first.start_with? '&' and not method.tags(:param).any?{ |t| t.name == e.first[1..-1] } } :
    method.parameters
  formatted = now_format_parameters_with_types(parameters, show_types ? method.tags(:param) : [])
  return '' if formatted.empty?
  '(%s)' % formatted
end

def now_format_block(method, show_types = !yield_documented?(method))
  params = now_format_block_params(method)
  return '' if params.nil?
  return '{ … }' if params.empty?
  '{ |%s|%s … }' % [now_format_parameters_with_types(params, show_types ? method.tags(:yieldparam) : []),
                    (show_types and yieldreturn_only_for_type?(method)) ?
                      now_format_arg_types_h(method.tag(:yieldreturn).types) :
                      '']
end

def now_format_parameters_with_types(parameters, tags)
  parameters.map{ |name, default|
    type = (tag = tags.find{ |e| e.name == name }) ?
      now_format_arg_types_h(tag.types) :
      ''
    (not type.empty? and default) ? '%s%s = <code class="default">%s</code>' % [h(name), type, h(default)] : '%s%s' % [h(name), type]
  }.join(', ')
end


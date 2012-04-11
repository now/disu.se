# -*- coding: utf-8 -*-

def init
  sections :method_signature, [T('docstring')]
end

def title_signature(method)
  '%s%s%s%s%s' % [method_name_h(method.name),
                  now_format_args(method),
                  now_format_block(method),
                  return_only_for_type_and_docstring?(method) ?
                    now_format_types_h(method.tags(:return).map{ |e| e.types or [] }.flatten.uniq) :
                    '',
                  method.visibility != :public ? '<sub class="visibility">%s</sub>' % method.visibility : '']
end

def now_format_args(method, show_types = !params_documented?(method))
  return '' if method.parameters.nil?
  parameters = (method.has_tag? :yield or method.has_tag? :yieldparam) ?
    method.parameters.reject{ |e| e.first.start_with? '&' and not method.tags(:param).any?{ |t| t.name == e.first[1..-1] } } :
    method.parameters
  return '' if parameters.empty?
  '(%s)' % now_format_parameters_with_types(parameters, show_types ? method.tags(:param) : [])
end

def now_format_block(method, show_types = !yield_documented?(method))
  params = now_block_params(method)
  return '' if params.nil?
  return '{ … }' if params.empty?
  '{ |%s|%s … }' % [now_format_parameters_with_types(params, show_types ? method.tags(:yieldparam) : []),
                    (show_types and yieldreturn_only_for_type? method) ?
                      now_format_types_h(method.tag(:yieldreturn).types) :
                      '']
end

def now_format_parameters_with_types(parameters, tags)
  parameters.map{ |name, default|
    type = (tag = tags.find{ |e| e.name == name }) ? now_format_types_h(tag.types) : nil
    [h(name), type, type ? now_format_default(default) : ''].join('')
  }.join(', ')
end


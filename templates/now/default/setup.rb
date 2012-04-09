# -*- coding: utf-8 -*-

def now_format_arg_types(types)
  types = %w'Object' if types.nil? or types.empty?
  result = title_signature_format_types(*types)
  types.length > 1 ? '[%s]' % result : result
end

def now_format_arg_types_h(types)
  '<sub class="type">%s</sub>' % now_format_arg_types(types)
end

def params_documented?(method)
  method.tags(:param).any?{ |e| e.text and not e.text.empty? }
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

def title_signature_format_types(*types)
  types.map{ |e|
    e.gsub(/([^\w:]*)([\w:]+)?/){ method_name_h($1) + ($2 ? linkify($2, $2) : '') }
  }.join(', ')
end

def now_format_parameters_with_types(parameters, tags)
  parameters.map{ |name, default|
    type = (tag = tags.find{ |e| e.name == name }) ?
      now_format_arg_types_h(tag.types) :
      ''
    default ? '%s%s = %s' % [h(name), type, h(default)] : '%s%s' % [h(name), type]
  }.join(', ')
end

def now_format_block_params(method)
  if method.has_tag? :yield and method.tag(:yield).types
    method.tag(:yield).types
  elsif method.has_tag? :yieldparam
    method.tags(:yieldparam).map(&:name)
  elsif method.has_tag? :yield
    []
  else
    nil
  end
end

def yield_documented?(method)
  # TODO: Shouldn’t we check the contents of the :yield tag?
  method.has_tag? :yield or method.tags(:yieldparam).any?{ |e| e.text and not e.text.empty? }
end

def yieldreturn_only_for_type?(method)
  not yield_documented? method and
    method.tags(:yieldreturn).size == 1 and
    (method.tag(:yieldreturn).text.nil? or method.tag(:yieldreturn).text.empty?) and
    not (params = now_format_block_params(method)).nil? and
    not params.empty?
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

def text_from_return(object)
  return '' unless object.tags(:return).size == 1 and not object.tag(:return).text.empty?
  text = object.tag(:return).text
  'Returns %s%s%s' % [text[0..0].downcase, text[1..-1], text.end_with?('.') ? '' : '.']
end

class YARD::Serializers::FileSystemSerializer
  class SerializedPath
    def initialize(object, extension)
      @object, @extension = object, extension
    end

    def call
      String === @object ? @object : extension(File.join(normalized))
    end

    private

    def normalized
      path.map{ |e| e.gsub(/[^\w.-]/){ |m| m.enum_for(:each_byte).map{ |b| '%X' % b }.join('') } }
    end

    def path
      CodeObjects::ExtraFileObject === @object ? ['file.%s' % object.name] : index
    end

    def index
      (@object.namespace ? @object.namespace.path.split(CodeObjects::NSEP).concat(basename) : basename).push('index')
    end

    def basename
      return [] if @object == YARD::Registry.root
      return ['%s_%s' % [@object.name.to_s, @object.scope.to_s[0, 1]]] if CodeObjects::MethodObject === @object
      [@object.name.to_s]
    end

    def extension(path)
      @extension.empty? ? path : '%s.%s' % [path, @extension]
    end
  end

  def serialized_path(object)
    SerializedPath.new(object, extension).call
  end
end

module YARD::Templates::Helpers::HtmlHelper
  Operators = {
    :[] => 'aref',
    :[]= => 'aset',
    :** => 'exponentiation',
    :! => 'not',
    :~ => 'complement',
    :+@ => 'unary-plus',
    :-@ => 'unary-minus',
    :* => 'multiplication',
    :/ => 'division',
    :% => 'modulo',
    :+ => 'addition',
    :- => 'subtraction',
    :>> => 'right-shift',
    :<< => 'left-shift',
    :& => 'and',
    :| => 'or',
    :^ => 'xor',
    :<= => 'less-than-or-equal',
    :< => 'less-than',
    :> => 'greater-than',
    :>= => 'greater-than-or-equal',
    :<=> => 'comparison',
    :== => 'equality',
    :!= => 'non-equality',
    :=== => 'case-equality',
    :=~ => 'match',
    :!~ => 'non-match'
  }
  def anchor_for(object)
    case object
    when CodeObjects::MethodObject
      Operators.include?(object.name) ?
        '%s-%s-operator' % [Operators[object.name], object.scope] :
        '%s-%s-method' % [object.name.to_s.sub(/\?\z/, '-p').sub(/!\z/, '-bang'), object.scope]
    when CodeObjects::ClassVariableObject
      '%s-class-variable' % object.name.to_s.sub('@@', '')
    when CodeObjects::Base
      '%s-%s' % [object.name, object.type]
    when CodeObjects::Proxy
      object.path
    else
      object.to_s
    end
  end

  def link_object(obj, otitle = nil, anchor = nil, relative = true)
    return otitle unless obj
    resolved = String === obj ? Registry.resolve(object, obj, true, true) : obj
    title = if otitle
              otitle.to_s
            elsif resolved.root?
              'Top-level Namespace'
            elsif String === obj
              CodeObjects::MethodObject === resolved ? method_name_h(obj) : h(obj)
            elsif CodeObjects::MethodObject === resolved and resolved.scope == :class and resolved.parent == object
              h([object.name, resolved.sep].join('')) + method_name_h(resolved.name)
            elsif CodeObjects::Base === object
              send(CodeObjects::MethodObject === resolved ? :method_name_h : :h, object.relative_path(resolved))
            elsif CodeObjects::MethodObject === resolved
              method_name_h(resolved.name)
            else
              h(resolved.to_s)
            end
    return title if not serializer or CodeObjects::Proxy === resolved
    link = url_for(resolved, anchor, relative)
    link ? link_url(link, title, :title => h('%s (%s)' % [resolved.path, resolved.type])) : title
  end

  def method_name_h(name)
    (start = (String === name and name.rindex(/[#.]/))) ?
      (Operators.include?(name[start+1..-1].to_sym) ? '%s<code>%s</code>' % [h(name[0..start]), h(name[start+1..-1])] : h(name)) :
      (Operators.include?(name.to_sym) ? '<code>%s</code>' % h(name) : h(name))
  end
end

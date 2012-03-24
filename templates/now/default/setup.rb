# -*- coding: utf-8 -*-

class YARD::CodeObjects::MethodObject
  def alias_for
    namespace.child(namespace.aliases[self])
  end
end

def now_format_object_title(object)
  '%s<sub class="type">%s</sub>' % [object.path, format_object_type(object)]
end

def now_inline_htmlify(object)
  htmlify(object).sub(%r'\A<p>', '').sub(%r'</p>', '')
end

def overloaded_format_args(method)
  method.tags(:overload).size > 1 && method.tags(:overload).map{ |e| format_args(e) + now_format_block(e) }.uniq.size > 1 ? '…' : format_args(method)
end

def overloaded_format_block(method)
  method.tags(:overload).size > 1 && method.tags(:overload).map{ |e| format_args(e) + now_format_block(e) }.uniq.size > 1 ? '' : now_format_block(method)
end

def now_format_block(object)
  if object.has_tag?(:yield) && object.tag(:yield).types
    params = object.tag(:yield).types
  elsif object.has_tag?(:yieldparam)
    params = object.tags(:yieldparam).map{ |t| t.name }
  elsif object.has_tag?(:yield)
    return '{ … }'
  else
    params = nil
  end
  params ? h('{ |' + params.join(', ') + '| … }') : ''
end

def title_signature(method)
  overload = convert_method_to_overload(method)
  types = overloaded_title_signature_types(overload)
  # TODO: Deal with overload.visibility?
  '%s%s%s%s' % [h(overload.name),
                overloaded_format_args(overload),
                overloaded_format_block(overload),
                types.empty? ? '' : '<sub class="type">%s</sub>' % types]
end

def overloaded_title_signature_types(method)
  method.tags(:overload).size > 1 && method.tags(:overload).map{ |e| title_signature_types(e) }.uniq.size > 1 ? '' : title_signature_types(method)
end

def title_signature_types(method)
  method = method.object if method.respond_to?(:object) and not method.has_tag?(:return)
  return h(options[:default_return]) unless method.tag(:return) and method.tag(:return).types
  types = method.tags(:return).map{ |e| e.types ? e.types : [] }.flatten.uniq
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

def title_signature_format_types(*types)
  return '' if types.empty?
  types.map{ |e|
    '<code>%s</code>' %
      e.gsub(/([^\w:]*)([\w:]+)?/){ h($1) + ($2 ? linkify($2, $2) : '') }
  }.join(', ')
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
end

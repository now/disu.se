# -*- coding: utf-8 -*-

def inline_overloads(method)
  return [] unless method
  return [method] if method.tags(:overload).empty?
  method.tags(:overload).map{ |e|
    n = method.dup
    unless e.signature.empty?
      n.signature = e.signature
      n.parameters = e.parameters.map{ |n, d| [n.to_s, d] }
    end
    n.docstring = e.docstring unless e.docstring.empty?
    n
  }
end

def fetch_shortest_unique_suffixes(hash, object)
  shortest_unique_suffixes(hash.fetch(object.path, []).map{ |e| [e.path.split('::'), e] }).
    map{ |p, e| r, s = object.relative_path(e), p.join('::'); [r.length < s.length ? r : s, e] }.
    sort_by{ |_, e| e.path }
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

def now_format_types(types)
  return now_format_types(%w'Object') if types.nil? or types.empty?
  return '%s<sup class="type">?</sup>' % now_format_types([types.first]) if
    types.size == 2 and types.last == 'nil'
  return '%s<sup class="type">+</sup>' % now_format_types([types.first]) if
    types.size == 2 and types.last =~ /\A(?:Array)?<#{Regexp.quote(types.first)}>\z/
  return '%s<sup class="type">*</sup>' % now_format_types([types.first]) if
    types.size == 2 and types.last == '…'
  types.map{ |e|
    e.gsub(/([^\w:]*)([\w:]+)?/){ method_name_h($1) + ($2 ? linkify($2, $2) : '') }
  }.join(', ')
end

def now_format_types_h(types, hclass = 'type')
  '<sub class="%s">%s</sub>' % [hclass, now_format_types(types)]
end

def now_format_default(default)
  default ? ' = <code class="default">%s</code>' % h(default) : ''
end

def now_block_params(method)
  if method.has_tag? :yield and method.tag(:yield).types and not yield_optional?(method)
    method.tag(:yield).types
  elsif method.has_tag? :yieldparam
    method.tags(:yieldparam).map(&:name)
  elsif method.has_tag? :yield
    []
  else
    nil
  end
end

def yield_optional?(method)
  method.has_tag? :yield and method.tag(:yield).types == ['?']
end

def params_documented?(method)
  method.tags(:param).any?{ |e| (e.text and not e.text.empty?) or method.tags(:option).any?{ |o| o.name == e.name } }
end

def yieldparams_documented?(method)
  method.tags(:yieldparam).any?{ |e| e.text and not e.text.empty? }
end

def yieldreturn_only_for_type?(method)
  method.tags(:yieldreturn).size == 1 and
    (method.tag(:yieldreturn).text.nil? or method.tag(:yieldreturn).text.empty?) and
    not (params = now_block_params(method)).nil? and
    not params.empty?
end

def return_only_for_type?(method)
  method.tags(:return).size == 1 and
    (method.tag(:return).text.nil? or method.tag(:return).text.empty?)
end

def return_used_for_docstring?(method)
  method.docstring.strip.empty? and
    method.tags(:return).size == 1 and
    not (method.tag(:return).text.nil? or method.tag(:return).text.empty?)
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
    resolved = if String === obj and obj == 'super' and
                   object.respond_to? :overridden_method and object.overridden_method
                 object.overridden_method
               elsif String === obj
                 Registry.resolve(object, obj, true, true)
               else
                 obj
               end
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

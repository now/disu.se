# -*- coding: utf-8 -*-

Tags::Library.labels[:todo] = 'TODO'

def init
  return if object.respond_to? :is_alias? and object.is_alias?
  tags = Tags::Library.visible_tags - [:option, :overload]
  tags.reject{ |t| respond_to? t }.each do |t|
    self.class.instance_eval do
      define_method t do
        tag(t)
      end
    end
  end
  sections :index, [:private] + tags
end

def private
  erb(:private) if object.has_tag? :api and object.tag(:api).text == 'private'
end

def return
  if object.type == :method and object.name == :initialize and object.scope == :instance
    warn 'return tag on #initialize method ignored' unless object.tags(:return).size == 1 and
      object.tag(:return).types.length == 1 and
      object.tag(:return).text == 'a new instance of %s' % object.tag(:return).types.first
    return
  end
  return if return_only_for_type_and_docstring? object
  return erb(:returns_void) if object.tags(:return).size == 1 and object.tag(:return).types == ['void']
  tag(:return)
end

def yieldreturn
  tag(:yieldreturn) unless yieldreturn_only_for_type? object
end

[:abstract, :deprecated, :example, :see].each do |t|
  define_method t do
    erb(t) if object.has_tag? t
  end
end

def param
  erb(:param) if params_documented? object
end

def yieldparam
  tag(:yieldparam) if yield_documented? object
end

private

def tag(name)
  return unless object.has_tag? name
  @name = name
  @label = Tags::Library.labels[name]
  @factory_method = Tags::Library.factory_method_for(name)
  @no_names, @no_types = case Tags::Library.factory_method_for(name)
                         when :with_types then          [true, false]
                         when :with_types_and_name then [false, false]
                         when :with_name then           [false, true]
                         else                           [true, true]
                         end
  erb(:tag)
end

def now_inline_htmlify(object)
  htmlify(object).sub(%r'\A<p>', '').sub(%r'</p>', '')
end

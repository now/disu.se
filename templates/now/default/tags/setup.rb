# -*- coding: utf-8 -*-

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
  return if object.docstring.strip.empty? or (object.tags(:return).size == 1 and (object.tag(:return).text.nil? or object.tag(:return).text.empty? or object.tag(:return).types == %w'self'))
  return erb(:returns_void) if object.tags(:return).size == 1 and
    object.tag(:return).types == ['void']
  erb(:return)
end

def yieldreturn
  erb(:yieldreturn) if object.has_tag? :yieldreturn and not yieldreturn_only_for_type? object
end

[:abstract, :deprecated, :example, :note, :see, :todo].each do |t|
  define_method t do
    erb(t) if object.has_tag? t
  end
end

def param
  tag(:param) if params_documented? object
end

def yieldparam
  tag(:yieldparam) if yield_documented? object
end

private

def tag(name)
  return unless object.has_tag?(name)
  @name = name
  @no_names, @no_types = case Tags::Library.factory_method_for(name)
                         when :with_types
                           [true, false]
                         when :with_types_and_name
                           [false, false]
                         when :with_name
                           [false, true]
                         else
                           [true, true]
                         end
  erb('tag')
end

def now_inline_htmlify(object)
  htmlify(object).sub(%r'\A<p>', '').sub(%r'</p>', '')
end

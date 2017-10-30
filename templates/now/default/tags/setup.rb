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
  if object.type == :method and object.scope == :instance and object.name == :initialize
    returns = object.tags(:return)
    warn 'return tag on #initialize method ignored' unless returns.size == 0 or
      (returns.size == 1 and
       returns.first.types.length == 1 and
       returns.first.text == 'a new instance of %s' % returns.first.types.first)
    return
  end
  return if return_only_for_type? object or return_used_for_docstring? object
  return erb(:returns_void) if object.tags(:return).size == 1 and object.tag(:return).types == ['void']
  tag(:return)
end

def yieldreturn
  tag(:yieldreturn) unless yieldreturn_only_for_type? object
end

def yield
  tag(:yield) if object.has_tag? :yield and not object.tag(:yield).text.empty?
end

[:abstract, :deprecated, :example, :see].each do |t|
  define_method t do
    erb(t) if object.has_tag? t
  end
end

def param
  if params_documented? object
    erb(:param)
  elsif object.tags(:option).any?{ |e| e.pair.text }
    erb(:option)
  end
end

def yieldparam
  tag(:yieldparam) if yieldparams_documented? object
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
  htmlify(object).sub(%r'\A\s*<p>', '').sub(%r'</p>\s*\z', '')
end

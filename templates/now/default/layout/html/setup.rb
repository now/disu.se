# -*- coding: utf-8 -*-

def init
  if @file
    if @file.attributes[:namespace]
      @object = options[:object] = Registry.at(@file.attributes[:namespace]) || Registry.root
    end
    @page_title = 'File: %s' % @file.title
    sections :layout, [:diskfile]
  elsif object
    @page_title = object.path
    sections :layout, [T(object.root? ? :module : object.type)]
  else
    # TODO: When’s this used?
    sections :layout, [:contents]
  end
end

def contents
  @contents
end

def diskfile
  @file.attributes[:markup] ||= markup_for_file('', @file.filename)
  htmlify(@file.contents, @file.attributes[:markup])
end

# @return [Array<String>] core stylesheets for the layout
# @since 0.7.0
def stylesheets
  %w(css/style.css css/common.css)
end

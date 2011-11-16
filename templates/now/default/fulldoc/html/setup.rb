# -*- coding: utf-8 -*-

include Helpers::ModuleHelper

def init
  options[:objects] = objects = run_verifier(options[:objects])

  generate_assets

  options[:files].each_with_index do |file, i|
    serialize_file file, file.title
  end

  options.delete :objects
  options.delete :files

  objects.each do |object|
    begin
      serialize object
    rescue => e
      log.error 'Exception occurred while serializing object: %s' %
        options[:serializer].serialized_path(object)
      log.backtrace e
    end
  end
end

def generate_assets
  @object = Registry.root
  (Object.new.extend(T('layout')).stylesheets + stylesheets_full_list).uniq.each do |file|
    asset file, file(file, true)
  end
end

def stylesheets_full_list
  %w(css/common.css)
end

# Generates a file to the output with the specified contents.
#
# @example saving a custom html file to the documenation root
#
#   asset('my_custom.html','<html><body>Custom File</body></html>')
#
# @param [String] path relative to the document output where the file will be
#   created.
# @param [String] content the contents that are saved to the file.
def asset(path, content)
  options[:serializer].serialize(path, content) if options[:serializer]
end

# Generate a single HTML file with the layout template applied. This is generally
# the README file or files specified on the command-line.
#
# @param [File] file object to be saved to the output
# @param [String] title currently unused
#
# @see layout#diskfile
def serialize_file(file, title = nil)
  options[:object] = Registry.root
  options[:file] = file
  serialize1 'file.%s.html' % file.name, options
  options.delete(:file)
end

def serialize1(what, options)
  Templates::Engine.with_serializer(what, options[:serializer]) do
    T('layout').run options
  end
end

# Generate an HTML document for the specified object. This method is used by
# most of the objects found in the Registry.
# @param [CodeObject] object to be saved to HTML
def serialize(object)
  options[:object] = object
  serialize1 object, options
end

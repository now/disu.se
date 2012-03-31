# -*- coding: utf-8 -*-

def init
  objects = run_verifier(options[:objects])
  options.delete :objects
  options.delete :files

  @object = Registry.root
  Object.new.extend(T('layout')).stylesheets.uniq.each do |file|
    options[:serializer].serialize(file, file(file, true)) if options[:serializer]
  end

  objects.each do |object|
    begin
      options[:object] = object
      Templates::Engine.with_serializer(object, options[:serializer]) do
        T('layout').run options
      end
    rescue => e
      log.error 'Exception occurred while serializing object: %s' %
        options[:serializer].serialized_path(object)
      if log.show_backtraces
        log.error '%s: %s' % [e.class.class_name, e.message]
        log.error "Stack trace: %s\n" % e.backtrace[0..5].join("\n")
      end
    end
  end
end

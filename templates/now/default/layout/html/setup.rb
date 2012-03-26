# -*- coding: utf-8 -*-

def init
  sections :layout, [T(object.root? ? :module : object.type)]
end

def stylesheets
  %w'css/style.css'
end

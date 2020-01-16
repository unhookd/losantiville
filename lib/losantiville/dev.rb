#

configure :development do
  register Sinatra::Reloader
  also_reload 'lib/losantiville/renderer.rb'
  after_reload do
    #NOTE: puts 'debug reload'
  end
end

# coding:utf-8
require 'yaml'
require 'active_record'
require 'sinatra'

class MainApp < Sinatra::Base
#  set :bind, '0.0.0.0'

  ActiveRecord::Base.configurations = YAML.load_file('database.yml')
  ActiveRecord::Base.establish_connection(:development)

  class App < ActiveRecord::Base
    self.inheritance_column = :_type_disabled
  end

  get '/steam/' do
    redirect '/steam/kuso'
  end

  get '/steam/kuso' do

    @app = App.where(type: 'game', all_review: 0..40).sample
    @title = "クソゲーおみくじ"
    erb :index

  end

  get '/steam/kami' do

    @app = App.where(type: 'game', all_review: 85..100).where('recommendations > 50').sample
    @title = "神ゲーおみくじ"
    erb :index
  
  end
end

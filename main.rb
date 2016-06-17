# coding:utf-8
require 'yaml'
require 'active_record'
require 'sinatra'
require 'net/http'
require 'rexml/document'

class MainApp < Sinatra::Base

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


  get '/steam/random' do

    erb :random

  end


  post '/steam/random' do

    profile_url = params[:profile_url]

    # http://steamcommunity.com/id/hogehoge
    # http://steamcommunity.com/id/hogehoge/
    # という形の文字列だけ通す
    if profile_url =~ /^http:\/\/steamcommunity\.com\/id\/\w+\/*?/ ||
       profile_url =~ /^http:\/\/steamcommunity\.com\/profiles\/\d+\/*?/
      # URI.joinだとうまくいかないのでFile.joinを使う
      gamelist_url = File.join(profile_url, 'games/?tab=all&xml=1') 

      gamelist = Net::HTTP.get(URI.parse(gamelist_url))

      begin
        doc = REXML::Document.new(gamelist)
      rescue REXML::ParseException => e
        @msg = "URLが不正です"
      end

      if doc.elements['response/error'].nil?
        if doc.elements['gamesList/error'].nil?
          # rexmlで全appIDノードを取得する方法がわからないから無理矢理
          appIDs = []
          doc.elements.each('gamesList/games/game/appID') do |node|
            appIDs.push(node.text)  
          end
          @app = App.find(appIDs.sample)
        else
          @msg = "このユーザのプロフィールは非公開です"
        end
      else
        @msg = "このプロフィールは存在しません"
      end
    else
      @msg = "Steam プロフィールの URL ではありません"
    end

    erb :random

  end

end

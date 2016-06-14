require 'net/http'
require 'uri'
require 'yaml'
require 'nokogiri'
require 'active_record'
require 'json'
require 'clockwork'

include Clockwork

ActiveRecord::Base.configurations = YAML.load_file('database.yml')
ActiveRecord::Base.establish_connection(:development)

class App < ActiveRecord::Base
  self.inheritance_column = :_type_disabled

  def previous
    App.where("appid < ?", self.appid).order("appid DESC").first
  end

  def next 
    App.where("appid > ?", self.appid).order("appid ASC").first
  end

end

# アプリ一覧を更新する
def update_applist

  applist_uri = 'http://api.steampowered.com/ISteamApps/GetAppList/v0001/'

  # アプリ一覧を取得して整形
  applist = JSON.load( open( applist_uri ) )
  apps = applist['applist']['apps']['app']

  # 全アプリのappid,nameをデータベースへ 
  apps.each do |app|
    if App.exists?(appid: app['appid'])
      new_app = App.find(app['appid'])
    else 
      new_app = App.new
    end

    new_app.update_attributes(appid: app['appid'], name: app['name'])

  end  

end

# Webコンテンツをダウンロード
def fetch(uri_str)
  uri = URI.parse(uri_str)
  response = Net::HTTP.get_response(uri)
  return response.body
end


# appdetailsを取得する
def get_appdetails(appid)

  appdetails_uri = 'http://store.steampowered.com/api/appdetails?appids=' + appid.to_s
  appdetails = JSON.parse(fetch(appdetails_uri))
  return appdetails[appid.to_s]

end

# ストアページからレビュー数、positiveの割合を取得する
def get_storeinfo(app)

  # アプリのレビュー数とpositiveの割合を取得
  # 年齢確認のページをパスするためCookieにbirthtimeを指定
  http = Net::HTTP.start('store.steampowered.com')
  response = http.get('/app/' + app.appid.to_s + '/?l=english',
                      'Cookie' => 'birthtime=-473417999;')
  html = response.body

  if html.empty? == false 

    html = Nokogiri::HTML.parse(html)

    # レビューの肯定率
    review_rates = get_review_rate(html)
    app.recent_review = review_rates[0]
    app.all_review    = review_rates[-1]

    # レビュー数
    app.recommendations = get_review_count(html)

    # タグ情報
    tags = get_tags(html)
    app.tags = tags.join(';')

  end

end 

# ストアページから最近のレビューと全レビューのpositive率を取得
def get_review_rate(storepage)

  if storepage.class != Nokogiri::HTML::Document
    storepage = Nokogiri::HTML.parse(storepage)
  end

  review_rate_class = 'span.nonresponsive_hidden.responsive_reviewdesc'
  review_rates = storepage.css(review_rate_class).inner_text.scan(/\d{,3}%/)
end

# ストアページからレビュー数を取得
def get_review_count(storepage)

  if storepage.class != Nokogiri::HTML::Document
    storepage = Nokogiri::HTML.parse(storepage)
  end

  # review_count_classはレビュー数が表示されているテキストのcssクラス
  review_count_class = 'span.responsive_hidden'
  recommendations = storepage.css(review_count_class).inner_text.scan(/[\,\d]+/)

  # カンマを削除
  recommendations = recommendations.map {|review_count| review_count.delete(',') }
  recommendations = recommendations[-1]

end

# ストアページからタグ情報を取得
def get_tags(storepage)

  if storepage.class != Nokogiri::HTML::Document
    storepage = Nokogiri::HTML.parse(storepage)
  end

  tag = storepage.css('.app_tag').inner_text.scan(/[\w\ \-]+/)
end

app = App.find(384421)

handler do |job|
  case job
  when 'update_applist.job'
    update_applist
  when 'get_storeinfo.job'

    if app == nil 
      app = App.first
    end   

    appdetails = get_appdetails(app.appid)

    if appdetails['success'] == true 
      app.type = appdetails['data']['type']

      get_storeinfo(app)

      app.update_attributes(
        recent_review: app.recent_review,
        all_review: app.all_review,
        recommendations: app.recommendations,
        type: app.type,
        tags: app.tags
      )
    end

    p "complete => #{app.appid}"

    app = app.next

  end
end

every(1.day, 'update_applsit.job', :at => '00:00')
every(2.seconds, 'get_storeinfo.job')

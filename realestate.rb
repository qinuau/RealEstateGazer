# coding: utf-8
require 'erb'
require 'mail'
require 'nokogiri'
require 'open-uri'
require 'pp'
require 'yaml'

sources = [
  {
    :name => 'suumo_chintai',
    :base_url => 'http://suumo.jp',
    :url => '',
    :each_xpath => "//div[@class='cassetteitem']",
    :title_xpath => "//div[@class='cassetteitem_content-title']",
    :category_xpath => "//span[@class='ui-pct ui-pct--util1 cassettebox-hpct cassettebox-hpctcat']",
    :lead_xpath => "//li[@class='cassetteitem_detail-col1']",
    :info_xpath => "//td",
    :each_url_xpath => "//td[@class='ui-text--midium ui-text--bold']//a",
  },
  {
    :name => 'suumo',
    :base_url => 'http://suumo.jp',
    :url => '',
    :each_xpath => "//li[@class='cassette js-bukkenCassette']",
    :title_xpath => "//h2[@class='cassettebox-title']//a",
    :category_xpath => "//span[@class='ui-pct ui-pct--util1 cassettebox-hpct cassettebox-hpctcat']",
    :lead_xpath => "//p[@class='infodatabox-lead']",
    :info_xpath => "//div[@class='infodatabox-box-txt']",
  },
  {
    :name => 'suumo_house',
    :base_url => 'http://suumo.jp',
    :url => '',
    :each_xpath => "//li[@class='cassette js-bukkenCassette']",
    :title_xpath => "//h2[@class='cassettebox-title']//a",
    :category_xpath => "//span[@class='ui-pct ui-pct--util1 cassettebox-hpct cassettebox-hpctcat']",
    :lead_xpath => "//p[@class='infodatabox-lead']",
    :info_xpath => "//div[@class='infodatabox-box-txt']",
  },
  {
    :name => 'o-uccino',
    :base_url => '',
    :url => '',
    :each_xpath => "//div[@class='article_detail']",
    :title_xpath => "//h3//a",
    :category_xpath => "",
    :lead_xpath => "//p[@class='text01']",
    :info_xpath => "//td",
  },
]

past_filename = 'past.txt'
past_datas = File.read(File.dirname(__FILE__) + '/' + past_filename)

result = ''
datas_for_past = ''

sources.each do |source|
  doc = Nokogiri::HTML(open(source[:url]))
  
  doc.xpath(source[:each_xpath]).each do |node|
    each_doc = Nokogiri::HTML(node.inner_html)
  
    @each_url = ''
    @title = ''
    @category = ''
    @lead = ''
    @info = []
    @address = ''
    @station = ''
    @bus = ''
    @price = ''
    @floor_plan = ''
    @past_years = ''
    
    each_doc.xpath(source[:title_xpath]).each do |node|
      @title = node.text.gsub(/(\r|\n|\t)/, '')
      #@each_url = source[:base_url] + node.get_attribute('href')
    end

    if source.has_key?(:each_url_xpath) && source[:each_url_xpath].empty? == false
      each_doc.xpath(source[:each_url_xpath]).each do |node|
        @each_url = node.get_attribute('href')
      end
    end
    
    if past_datas.match(/^#{@title}$/)
      next
    else
      datas_for_past += @title + "\n"
    end

=begin
    each_doc.xpath(source[:category_xpath]).each do |node|
      @category = node.text.gsub(/(\r|\n|\t)/, '')
    end
=end
  
    each_doc.xpath(source[:lead_xpath]).each do |node|
      @lead = node.text.gsub(/(\r|\n|\t)/, '')
    end
  
    each_doc.xpath(source[:info_xpath]).each do |node|
      @info.push(node.text.gsub(/(\r|\n|\t)/, ''))
    end

    if source[:name] == 'suumo'
      @address = @info[0]
      @station = @info[1]
      @bus = @info[2]
      @price = @info[3]
      @floor_plan = @info[4]
      @past_years = @info[5]
    elsif source[:name] == 'o-uccino'
      if @info[4].match(/m2$/)
        @address = @info[2]
      else
        @address = @info[4]
      end
      @station = ''
      @bus = ''
      @price = @info[0]
      @floor_plan = @info[5] + ' ' + @info[6]
      @past_years = @info[8]
    elsif source[:name] == 'suumo_chintai'
      @price = @info[3]
      @floor_plan = @info[2] + ' ' + @info[6] + ' ' + @info[7]
    end
    
    template = ERB.new(File.read(File.dirname(__FILE__) + '/template/main.erb'))
    result += template.result
  end
end

conf = YAML.load(File.read('conf.yml'))

if result != ''
  to = conf['conf']['email']
  
  mail = Mail.new do
    from    'system@qinuau.net'
    to      to
    subject 'Qinuauの物件ニュース'
    body    result
  end
  
  mail.charset = 'utf-8' 
  
  mail.delivery_method(:smtp,
    ssl: nil,
    enable_starttls_auto: nil,
    openssl_verify_mode: nil,
  )
  
  mail.deliver
  
  f = open(File.dirname(__FILE__) + '/' + past_filename, 'a')
  f.puts(datas_for_past)
  f.close
end

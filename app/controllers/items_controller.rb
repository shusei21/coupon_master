class ItemsController < ApplicationController
	def set_token
		token = Token.find_by(user_id:current_user.id)
		@service_secret = token.service_secret
		@license_key = token.license_key
	end

	def set_itemurls
		#reserves = Reserve.where(user_id:current_user.id)
		#reserves_itemid = reserves.pluck(:item_id)
		#items = Item.where(id:reserves_itemid)
		#coupon_id = items.pluck(:coupon_id)
		#coupons = Coupon.where(id:coupon_id)
		#@itemurls = items.pluck(:itemurl)
		@reserves = Reserve.where(user_id:current_user.id).includes(:item).includes(:coupon)
	end


	def add_update
		set_token
		set_itemurls
		require 'net/https'
    require 'uri'
    require 'rexml/document'
    @items = []
		@insert_item = []

    get_uri = URI.parse("https://api.rms.rakuten.co.jp/es/1.0/item/get")

    update_uri = URI.parse("https://api.rms.rakuten.co.jp/es/1.0/item/update")
		
    if @reserves.present?
			@reserves.each do |reserve|
				get_uri.query = URI.encode_www_form({ 'itemUrl': reserve.item.itemurl })
				
				http = Net::HTTP.new(get_uri.host, get_uri.port)
		    http.use_ssl = true

		    license_key = Base64.strict_encode64("#{@service_secret}:#{@license_key}")
		    auth_key = license_key.gsub(/\r?\n/,"")


		    req = Net::HTTP::Get.new(get_uri.request_uri)
		    req["Authorization"] = "ESA " + auth_key

		    get_response = http.request(req)
		    xml = get_response.body

		    doc = Nokogiri::XML(xml)

		    html_pc = doc.xpath('//descriptionBySalesMethod').text
		    html_sp = doc.xpath('//descriptionForSmartPhone').text

		    pc_tag_count = html_pc.scan("<!--coupon start-->").length
		    sp_tag_count = html_sp.scan("<!--coupon start-->").length

		    #追加するHTMLを定義
		    pc_insert_word = "<div class=\"common-bnr\">\n<a href=\"#{reserve.coupon.common_url}\">\n<img src=\"#{reserve.coupon.common_bnr}\">\n</a></div><br>\n<div class=\"coupon-bnr\">\n<a href=\"#{reserve.coupon.coupon_url}\">\n<img src=\"https://image.rakuten.co.jp/be-garden/cabinet/campaign/couponget/#{reserve.coupon.coupon_bnr}\">\n</a></div><br>"
		    sp_insert_word = "<a href=\"#{reserve.coupon.common_url}\">\n<img src=\"#{reserve.coupon.common_bnr}\" width=\"100%\">\n</a><br>\n<a href=\"#{reserve.coupon.coupon_url}\">\n<img src=\"https://image.rakuten.co.jp/be-garden/cabinet/campaign/couponget/#{reserve.coupon.coupon_bnr}\" width=\"100%\">\n</a><br>"
		    #追加するHTMLを定義

		    pc_num = 0
		    pc_insert_point = 0
		    pc_insert = html_pc

		    if pc_tag_count == 0
		    	pc_insert = pc_insert.insert(pc_insert_point, "<!--coupon start-->\n#{pc_insert_word}\n<!--coupon end-->\n")
		    else
		    	while pc_num < pc_tag_count do
		    		pc_markup_point = pc_insert.index('<!--coupon start-->',pc_insert_point)
			    	pc_insert_point = pc_markup_point + 20
			    	pc_insert = pc_insert.insert(pc_insert_point, "#{pc_insert_word}\n")
			    	pc_num += 1
			    end
			  end

		    sp_num = 0
		    sp_insert_point = 0
		    sp_insert = html_sp

		    if sp_tag_count == 0
		    	sp_insert = sp_insert.insert(sp_insert_point, "<!--coupon start-->\n#{sp_insert_word}\n<!--coupon end-->\n")
		    else
		    	while sp_num < sp_tag_count do
		    		sp_markup_point = sp_insert.index('<!--coupon start-->',sp_insert_point)
			    	sp_insert_point = sp_markup_point + 20
			    	sp_insert = sp_insert.insert(sp_insert_point, "#{sp_insert_word}\n")
			    	sp_num += 1
			    end
			  end

		    data = REXML::Document.new(<<-XML)
		    <?xml version="1.0" encoding="UTF-8"?>
					<request>
					  <itemUpdateRequest>
					    <item>
					    	<itemUrl>#{reserve.item.itemurl}</itemUrl>
					    	<descriptionForSmartPhone><![CDATA[#{sp_insert}]]></descriptionForSmartPhone>
						    <descriptionBySalesMethod><![CDATA[#{pc_insert}]]></descriptionBySalesMethod>
					    </item>
					  </itemUpdateRequest>
					</request>
				XML
				#XMLの中に要素としてHTMLを書くときは、<![CDATA[  -HTML要素-  ]]>で囲む

				header ={
		      'Content-Type' => "text/xml",
		      'Authorization' => 'ESA ' + Base64.strict_encode64("#{@service_secret}:#{@license_key}")
		    }
		    @header = header

		    http = Net::HTTP.new(update_uri.host, update_uri.port)
		    http.use_ssl = true
		    xmldata = StringIO.new
		    data.write(xmldata)
		    @xmldata = xmldata.string
		    update_response = http.post(update_uri.path, xmldata.string, header)
		    update_response_body = update_response.body

		    @body = update_response.body
		    @insert_item.push(update_response_body)

		    response_xml = REXML::Document.new(update_response_body)


		    #エラーがあるか確認(エラーがある場合)
		    unless response_xml.elements["result/itemUpdateResult/code"].text = "N000"
		    	error_ids = []
		    	field_ids = []
		    	error_messages = []
		    	response_xml.elements.each("result/itemUpdateResult/errorMessages/errorId") do |errorid|
		    		error_ids.push(errorid.text)
		    	end
		    	response_xml.elements.each("result/itemUpdateResult/errorMessages/fieldId") do |fieldid|
		    		field_ids.push(fieldid.text)
		    	end
		    	response_xml.elements.each("result/itemUpdateResult/errorMessages/msg") do |msg|
		    		error_messages.push(msg.text)
		    	end

		    	error_ids.each do |error_id|
		    		field_ids.each do |field_id|
		    			error_messages.each do |error_message|
		    				ItemUpdateError.create(itemurl: reserve.item.itemurl,error_id:error_id,field_id:field_id,error_message:error_message,reserve_id:reserve.id)
		    			end
		    		end
		    	end

		    end
		    sleep(1)
	    end
	    redirect_to coupons_top_path, notice: "商品ページを更新しました"
	  else
	  	redirect_to coupons_top_path, notice: "更新予約中の商品がありません"
	  end
	end

	def remove_update
		set_token
		set_itemurls
		require 'net/https'
    require 'uri'
    require 'rexml/document'

    get_uri = URI.parse("https://api.rms.rakuten.co.jp/es/1.0/item/get")

    update_uri = URI.parse("https://api.rms.rakuten.co.jp/es/1.0/item/update")
    @items = []
		@insert_item = []

		if @reserves.present?
			@reserves.each do |reserve|
				get_uri.query = URI.encode_www_form({ 'itemUrl': reserve.item.itemurl })
				
				http = Net::HTTP.new(get_uri.host, get_uri.port)
		    http.use_ssl = true

		    license_key = Base64.strict_encode64("#{@service_secret}:#{@license_key}")
		    auth_key = license_key.gsub(/\r?\n/,"")


		    req = Net::HTTP::Get.new(get_uri.request_uri)
		    req["Authorization"] = "ESA " + auth_key

		    get_response = http.request(req)
		    xml = get_response.body

		    doc = Nokogiri::XML(xml)

		    html_pc = doc.xpath('//descriptionBySalesMethod').text
		    html_sp = doc.xpath('//descriptionForSmartPhone').text

		    pc_tag_count = html_pc.scan("<!--coupon start-->").length
		    sp_tag_count = html_sp.scan("<!--coupon start-->").length


		    pc_num = 0
		    pc_remove_point = 0
		    pc_remove = html_pc

		    if pc_tag_count > 0
		    	while pc_num < pc_tag_count do
		    		pc_markup_point_start = pc_remove.index('<!--coupon start-->',pc_remove_point) + 20
		    		pc_markup_point_end = pc_remove.index('<!--coupon end-->',pc_remove_point) - 1
			    	pc_remove_point = pc_markup_point_start + 18
			    	pc_remove.slice!(pc_markup_point_start..pc_markup_point_end)
			    	pc_num += 1
			    end
			  end

			  sp_num = 0
		    sp_remove_point = 0
		    sp_remove = html_sp

			  if sp_tag_count != 0
		    	while sp_num < sp_tag_count do
		    		sp_markup_point_start = sp_remove.index('<!--coupon start-->',sp_remove_point) + 20
		    		sp_markup_point_end = sp_remove.index('<!--coupon end-->',sp_remove_point) - 1
			    	sp_remove_point = sp_markup_point_end + 18
			    	sp_remove.slice!(sp_markup_point_start..sp_markup_point_end)
			    	sp_num += 1
			    end
			  end

			  data = REXML::Document.new(<<-XML)
		    <?xml version="1.0" encoding="UTF-8"?>
					<request>
					  <itemUpdateRequest>
					    <item>
					    	<itemUrl>#{reserve.item.itemurl}</itemUrl>
					    	<descriptionForSmartPhone><![CDATA[#{sp_remove}]]></descriptionForSmartPhone>
						    <descriptionBySalesMethod><![CDATA[#{pc_remove}]]></descriptionBySalesMethod>
					    </item>
					  </itemUpdateRequest>
					</request>
				XML
				#XMLの中に要素としてHTMLを書くときは、<![CDATA[  -HTML要素-  ]]>で囲む

				header ={
		      'Content-Type' => "text/xml",
		      'Authorization' => 'ESA ' + Base64.strict_encode64("#{@service_secret}:#{@license_key}")
		    }
		    @header = header

		    http = Net::HTTP.new(update_uri.host, update_uri.port)
		    http.use_ssl = true
		    xmldata = StringIO.new
		    data.write(xmldata)
		    @xmldata = xmldata.string
		    update_response = http.post(update_uri.path, xmldata.string, header)
		    update_response_body = update_response.body
		    @body = update_response.body
		    @insert_item.push(update_response_body)

		    Reserve.find(reserve.id).delete
		    sleep(1)
			end
			redirect_to coupons_top_path, notice: "商品ページを更新しました"
		else
			redirect_to coupons_top_path, notice: "更新予約中の商品がありません"
		end
	end

end

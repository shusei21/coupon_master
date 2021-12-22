class CouponsController < ApplicationController
	def set_coupon
		new_csv = Csv.where(user_id: current_user.id).order(created_at: :desc).first
		@coupons = Coupon.where(csv_id: new_csv.id)
	end

	def set_token
		token = Token.find_by(user_id:current_user.id)
		@service_secret = token.service_secret
		@license_key = token.license_key
	end

	def top
		set_token
    require 'net/https'
    require 'uri'
    require 'base64'
    require 'nokogiri'
    require 'date'

    target_uri = "https://api.rms.rakuten.co.jp/es/1.0/coupon/search"
    uri = URI.parse(target_uri)

    couponName = '200604'
    couponCode = 'XLOD-GXBR-U9FU-1QHU'
    hits = '30'

    uri.query = URI.encode_www_form({ 'hits': hits })

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    license_key = Base64.strict_encode64("#{@service_secret}:#{@license_key}")
    auth_key = license_key.gsub(/\r?\n/,"")


    req = Net::HTTP::Get.new(uri.request_uri)
    req["Authorization"] = "ESA " + auth_key

    response = http.request(req)
    xml = response.body

    doc = Nokogiri::XML(xml)
    @coupons = doc.xpath('//coupon')
	end


	def index
		set_coupon
	end


	def create
		set_coupon
		set_token
    require 'net/https'
    require 'uri'
    require 'rexml/document'

    uri = URI.parse("https://api.rms.rakuten.co.jp/es/1.0/coupon/issue")

    @coupons.each do |coupon|

	    data = REXML::Document.new(<<-XML)
	    <?xml version="1.0" encoding="UTF-8"?>
	      <request>
	        <couponIssueRequest>
	          <coupon>
	            <couponName>#{coupon.name}</couponName>
	            <couponCaption>#{coupon.caption}</couponCaption>
	            <couponStartDate>#{DateTime.parse(coupon.startdate.to_s)}</couponStartDate>
	            <couponEndDate>#{DateTime.parse(coupon.enddate.to_s)}</couponEndDate>
	            <couponImage>#{coupon.image}</couponImage>
	            <issueCount>#{coupon.issuecount}</issueCount>
	            <itemType>#{coupon.itemtype}</itemType>
	            <discountType>#{coupon.discounttype}</discountType>
	            <discountFactor>#{coupon.discountfactor}</discountFactor>
	            <memberAvailMaxCount>#{coupon.maxcount}</memberAvailMaxCount>
	            <multiRankCond>
	              <rankCond>#{coupon.rankcond}</rankCond>
	            </multiRankCond>
	            <combineFlag>#{coupon.combineflag}</combineFlag>
	            <displayFlag>#{coupon.displayflag}</displayFlag>
	            <items>
	              <item>
	                <itemUrl>#{coupon.itemurl}</itemUrl>
	              </item>
	            </items>
	            <otherConditions>
	              <otherCondition>
	                <conditionTypeCode>#{coupon.conditiontype}</conditionTypeCode>
	                <startValue>#{coupon.startvalue}</startValue>
	              </otherCondition>
	            </otherConditions>
	          </coupon>
	        </couponIssueRequest>
	      </request>
	    XML

	      #商品ID複数指定の場合の処理
	      num_item = 1

	      if coupon.itemtype = 3
	        items = coupon.itemurl.split(" ")
	        data.elements.delete("request/couponIssueRequest/coupon/items/item")

	        items.each do |item|
	          items_xml = data.elements["request/couponIssueRequest/coupon/items"]
	          add_item = REXML::Element.new('item')
	          items_xml.add_element(add_item)

	          item_xml = data.elements["request/couponIssueRequest/coupon/items/item[#{num_item}]"]
	          add_itemurl = REXML::Element.new('itemUrl')
	          item_xml.add_element(add_itemurl).add_text(item)

	          num_item += 1
	        end
	      end

	      #会員ランク複数指定の場合の処理
	      num_rank = 1

	      if coupon.rankcond != 0
	        rankConds = coupon.rankcond.split(" ")
	        data.elements.delete("request/couponIssueRequest/coupon/multiRankCond/rankCond")

	        rankConds.each do |rankCond|
	          rankConds_xml = data.elements["request/couponIssueRequest/coupon/multiRankCond"]
	          add_rankCond = REXML::Element.new('rankCond')
	          rankConds_xml.add_element(add_rankCond)

	          rankCond_xml = data.elements["request/couponIssueRequest/coupon/multiRankCond/rankCond[#{num_rank}]"]
	          rankCond_xml.add_text(rankCond)

	          num_rank += 1
	        end
	      end

	    header ={
	      'Content-Type' => "application/xml",
	      'Authorization' => 'ESA ' + Base64.strict_encode64("#{@service_secret}:#{@license_key}")
	    }

	    http = Net::HTTP.new(uri.host, uri.port)
	    http.use_ssl = true
	    xmldata = StringIO.new
	    data.write(xmldata)
	    response = http.post(uri.path, xmldata.string, header)

	    @body = response.body # APIからのresponseのxmlをそのまま返す
	    @code = response.code # ステータスコードを返す
	    @req = data


	    response_xml = REXML::Document.new(response.body)

	    

	    #エラーの有無を判断
	    if response_xml.elements["result/coupon/couponCode"].present? #エラーなし

		  	#coupon_id、coupon_url、startdate、enddate、image_nameをitemsテーブルに保存
		    items = coupon.itemurl.split(" ")

		      items.each do |item|
		        coupon_code = response_xml.elements["result/coupon/couponCode"].text
				  	coupon_url = response_xml.elements["result/coupon/pcGetUrl"].text
				  	startdate = DateTime.parse(coupon.startdate.to_s)
				  	enddate = DateTime.parse(coupon.enddate.to_s)
				  	coupon.update(coupon_url:coupon_url, coupon_code:coupon_code)

				  	if coupon.coupon_bnr == "auto"
					  	if coupon.discounttype == 1
					  		imagename = "#{item}_#{coupon.discountfactor}y.jpg"
					  	elsif coupon.discounttype == 2 
					  		imagename = "#{item}_#{coupon.discountfactor}p.jpg"
					  	else
					  		imagename = "#{item}_fd.jpg"
					  	end
					  	coupon.update(coupon_bnr: imagename)
					  end

				  	Item.create(coupon_id: coupon.id, startdate:startdate, enddate:enddate,itemurl:item)
		      end


		  else #エラーあり
		  	error_codes = [] #エラーコードを保存する配列
		    error_messages = [] #エラーメッセージを保存する配列
		    response_xml.elements.each("result/errors/error/code") do |code|
		    	error_codes.push(code.text)
		    end
		    response_xml.elements.each("result/errors/error/message") do |message|
		    	error_messages.push(message.text)
		    end

		    #エラーコードとメッセージを、coupon_id、coupon_nameと一緒にErrorテーブルに保存
		    error_codes.each do |code|
		    	error_messages.each do |message|
			    	Error.create(coupon_id: coupon.id,coupon_name: coupon.name,error_code: code,error_message: message)
			    end
		  	end
	 		end


		 	reserve_items = Item.where(coupon_id: coupon.id)
		 	reserve_items.each do |reserve_item|
	 		if coupon.coupon_bnr.present? || coupon.common_bnr.present?
	 			Reserve.create(item_id:reserve_item.id, user_id:current_user.id)
	 		end
		 	end

    end

    @error_cnt = 0
    @coupons.each do |coupon|
    	error_cnt_part = Error.where(coupon_id: coupon.id).count
    	@error_cnt += error_cnt_part
    end




    
    if @error_cnt > 0
    	redirect_to coupons_top_path, notice: "#{@error_cnt}件のエラーがあります"
  	else
  		redirect_to coupons_top_path, notice: "クーポンを登録しました。"
  	end

	end
end

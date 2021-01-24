class LineBotController < ApplicationController
  protect_from_forgery except: [:callback]

  def callback
    body = request.body.read
    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      # p '不正なリクエストです'
      head :bad_request
    end
    # p '正しいリクエストです'
    events = client.parse_events_from(body)
    events.each do |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          # message = {
          #   type: 'text',
          #   text: event.message['text']
          # }
          # message = {
          #   type: 'sticker',
          #   packageId: 1,
          #   stickerId: 1
          # }
          message = {
            "type": 'template',
            "altText": 'This is a buttons template',
            "template": {
              "type": 'buttons',
              "thumbnailImageUrl": 'https://example.com/bot/images/image.jpg',
              "imageAspectRatio": 'rectangle',
              "imageSize": 'cover',
              "imageBackgroundColor": '#FFFFFF',
              "title": 'Menu',
              "text": 'Please select',
              "defaultAction": {
                "type": 'uri',
                "label": 'View detail',
                "uri": 'http://example.com/page/123'
              },
              "actions": [
                {
                  "type": 'postback',
                  "label": 'Buy',
                  "data": 'action=buy&itemid=123'
                },
                {
                  "type": 'postback',
                  "label": 'Add to cart',
                  "data": 'action=add&itemid=123'
                },
                {
                  "type": 'uri',
                  "label": 'View detail',
                  "uri": 'http://example.com/page/123'
                }
              ]
            }
          }
          client.reply_message(event['replyToken'], message)
        end
      end
    end
    head :ok
  end

  private

  def client
    @client ||= Line::Bot::Client.new do |config|
      config.channel_secret = ENV['LINE_CHANNEL_SECRET']
      config.channel_token = ENV['LINE_CHANNEL_TOKEN']
    end
  end
end

class Service::Sprintly < Service::Base
  title 'Sprint.ly'

  string :dashboard_url, :placeholder => 'https://sprint.ly/product/1/',
         :label => 'URL for your Sprint.ly product dashboard'
  string :email, :placeholder => 'email',
         :label => 'These values are encrypted to ensure your security. <br /><br />' \
                   'Your Sprint.ly email:'
  password :api_key, :placeholder => 'Sprint.ly API key',
           :label => 'Your Sprint.ly API key:'

  page 'Product', [:dashboard_url]
  page 'Login Information', [:email, :api_key]

  def receive_verification(config, _)
    begin
      url = items_api_url_from_dashboard_url(config[:dashboard_url])
      http.ssl[:verify] = true
      http.basic_auth config[:email], config[:api_key]

      resp = http_get url
      if resp.status == 200
        [true,  'Successfully verified Sprint.ly settings!']
      else
        log "Sprint.ly error: #{error_response_details(resp)}"
        [false, "Oops! Please check your settings again."]
      end
    rescue => e
      log "Rescued a verification error in Sprint.ly: (url=#{config[:dashboard_url]}) #{e}"
      [false, "Oops! Please check your settings again."]
    end
  end

  # Create a defect on Sprint.ly
  def receive_issue_impact_change(config, payload)
    url = items_api_url_from_dashboard_url(config[:dashboard_url])
    http.ssl[:verify] = true
    http.basic_auth config[:email], config[:api_key]

    post_body = {
      :type => 'defect',
      :title => payload[:title] + ' [Crashlytics]',
      :description => sprintly_issue_description(payload)
    }

    resp = http_post url do |req|
      req.body = post_body
    end

    if resp.status == 200
      { :sprintly_item_number => JSON.parse(resp.body)['number'] }
    else
      raise "[Sprint.ly] Adding defect to backlog failed - #{error_response_details(resp)}"
    end
  end

  private
  def sprintly_issue_description(payload)
    users_text = if payload[:impacted_devices_count] == 1
      'This issue is affecting at least 1 user who has crashed '
    else
      "This issue is affecting at least #{ payload[:impacted_devices_count] } users who have crashed "
    end

    crashes_text = if payload[:crashes_count] == 1
      "at least 1 time."
    else
      "at least #{ payload[:crashes_count] } times."
    end

    "Crashlytics detected a new issue.\n" + \
       "#{ payload[:title] } in #{ payload[:method] }\n\n" + \
       users_text + crashes_text + "\n\n" + \
       "More information: #{ payload[:url] }"
  end

  require 'uri'
  def items_api_url_from_dashboard_url(url)
    uri = URI(url)
    product_id = url.match(/(https?:\/\/.*?)\/product\/(\d*)(\/|$)/)[2]
    "https://sprint.ly/api/products/#{product_id}/items.json"
  end
end

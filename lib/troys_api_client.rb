class TroysAPIClient

  attr_accessor :subdomain, :api_key, :protocol, :platform, :host,
                :base_url, :api_version
  attr_accessor :last_response

  def initialize(subdomain, api_key, platform: 'repairshopr', host: nil, ssl: nil)
    @subdomain = subdomain
    @api_key = api_key

    @protocol = ssl if ssl.is_a?(String)
    @protocol ||= (Rails.env.development? ? 'http' : 'https') if ssl.nil?
    @protocol ||= ssl ? 'https' : 'http'

    @platform = %w[repairshopr syncro].detect {|k| k == platform } or raise "Invalid platform '#{platform}'"
    @host = host || determine_host
    @base_url = "#{@protocol}://#{@subdomain}.#{@host}"

    @api_version = "/api/v1"
  end

  def determine_host
    return ENV['RSYN_HOST'] if Rails.env.development?
    if platform == 'syncro'
      'syncromsp.com'
    else
      'repairshopr.com'
    end
  end

  def authentic?
    authenticate
    # 401 Unauthorized for invalid api_key
    @last_response.status == 200
  end

  def authenticate
    get "me"
  end

  def customers
    get "customers.json"
  end

  def search_customers(query)
    get "customers.json", query: query
  end

  def autocomplete query
    get "customers/autocomplete.json", query: query
  end

  def invoices
    get "invoices.json"
  end

  def tickets
    get "tickets.json"
  end

  def vendors
    get "vendors.json"
  end

  def schedules
    get "schedules.json"
  end

  def create_customer params
    post "customers.json", params
  end

  def create_vendor params
    post "vendors.json", params
  end

  def create_schedule params
    post "schedules.json", params
  end

  def demo_customer
    new_cust = {}
    new_cust[:firstname] = 'JonnyAPI'
    new_cust[:lastname] = 'SmithAPI'
    new_cust[:phone] = '4256611'
    new_cust[:email] = 'john+123@repairshopr.com'
    create_customer new_cust
  end


  def create_invoice params
    post "invoices.json", params
  end

  def create_ticket params
    post "tickets.json", params
  end

  def create_comment params
    post "tickets/#{params[:number]}/comment.json", params
  end

  def create_asset params
    post "customer_assets.json", params
  end

  def demo_invoice
    new_invoice = {}
    new_invoice[:customer_id] = '120018'
    new_invoice[:date] = '2013-05-25'
    new_invoice[:line_items] = [
        {item: 'Some Item', name: 'Some big description', cost: 0.0, price: 19.99, quantity: 1}
    ]
    create_invoice new_invoice
  end

  # Framework/Foundational helpers
  def setup_connection
    @conn = Faraday.new(
        url: "#{base_url}/#{api_version}",
        params: {api_key: api_key},
        ) do |faraday|
      faraday.request  :url_encoded             # form-encode POST params
      faraday.response :logger                  # log requests to STDOUT
      faraday.adapter  Faraday.default_adapter  # make requests with Net::HTTP
    end
  end

  def get(path, params = {})
    setup_connection
    @last_response = @conn.get(path, params)
    JSON.parse @last_response.body
  end

  def post(path, params = {})
    setup_connection
    @last_response = @conn.post(path, params)
    JSON.parse @last_response.body
  end

  # eg `client.create_or_update('customer_assets', asset)` does not manage pluralization of route
  def create_or_update type, params
    setup_connection

    id = params.delete(:id)
    url = [type, id].compact.join('/')

    payload = params
    payload[:format] = 'json'

    @last_response = if id.present?
      @conn.put(url, params)
    else
      @conn.post(url, params)
    end

    JSON.parse @last_response.body
  end

end

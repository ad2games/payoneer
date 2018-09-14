module PayoneerClient
  def payoneer_client
    @payoneer_client ||= Payoneer.new(partner_id: ENV['PAYONEER_PARTNER_ID'],
                                      username: ENV['PAYONEER_USERNAME'],
                                      password: ENV['PAYONEER_PASSWORD'],
                                      sandbox: true)
  end
end

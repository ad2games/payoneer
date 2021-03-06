describe 'Payoneer#transfer_funds', :vcr do
  it 'transfers funds to a payee' do
    expect(payoneer_client.transfer_funds(
      program_id: 'foo',
      internal_payment_id: 1,
      internal_payee_id: 'fox',
      amount: 20.00,
      description: 'Fox stuff',
      date: Time.new(2014, 10, 7, 9, 38, 24),
    )).to eq(true)
  end
end

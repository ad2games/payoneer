describe Payoneer do
  subject do
    Payoneer.new(
      partner_id: 'x',
      username: 'y',
      password: 'z',
      sandbox: true
    )
  end

  describe '#transfer_funds_args' do
    let(:time) { Time.new(2014, 10, 7, 16, 50, 10) }
    it 'uses the current time for the payment timestamp param if none is given' do
      expect(Time).to receive(:now).and_return(time)
      expect(subject.send(:transfer_funds_args, {}))
        .to include('p9' => '10/07/2014 16:50:10')
    end

    it 'uses the timestamp from the options hash if present' do
      expect(subject.send(:transfer_funds_args, { date: time }))
        .to include('p9' => '10/07/2014 16:50:10')
    end
  end

  describe '#to_struct' do
    it "turns the API's response into a struct" do
      struct = subject.send(:to_struct, <<-XML)
        <?xml version='1.0' encoding='ISO-8859-1' ?>
        <GetPaymentStatus>
          <PaymentId>1</PaymentId>
          <Result>000</Result>
          <Description>OK (Request accepted)</Description>
          <PaymentDate>10/7/2014 3:38:23 AM</PaymentDate>
          <Amount>20.00</Amount>
          <Status>Pending Payee Approval</Status>
          <LoadDate>1/1/1970</LoadDate>
          <Curr>USD</Curr>
        </GetPaymentStatus>
      XML

      expect(struct.payment_id).to eq('1')
      expect(struct.result).to eq('000')
      expect(struct.description).to eq('OK (Request accepted)')
      expect(struct.payment_date).to eq('10/7/2014 3:38:23 AM')
      expect(struct.amount).to eq('20.00')
      expect(struct.status).to eq('Pending Payee Approval')
      expect(struct.load_date).to eq('1/1/1970')
      expect(struct.curr).to eq('USD')
    end
  end
end

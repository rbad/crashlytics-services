require 'spec_helper'

describe Service::Sms do
  let(:config) do
    {
      :phone_number => '867.5309',
    }
  end

  it 'has a title' do
    expect(Service::Sms.title).to eq('SMS')
  end

  describe '#receive_verification' do
    it :success do
      service = Service::Sms.new('verification', {})
      success, message = service.receive_verification(config, nil)
      expect(success).to be true
    end

    it :failure do
      # not yet implemented.
    end
  end
  
end

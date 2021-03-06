# frozen_string_literal: true

require 'rails_helper'

describe ::Caffeinate::Campaign do
  let(:campaign) { create(:caffeinate_campaign, :with_dripper) }

  describe '#to_dripper' do
    it 'resolves to a dripper' do
      expect(campaign.to_dripper.superclass).to eq(Caffeinate::Dripper::Base)
    end
  end

  describe '#subscribe!' do
    context 'without args' do
      let(:company) { create(:company) }

      it 'returns a CampaignSubscription with the subscriber being the first argument' do
        subscriber = campaign.subscribe!(company)
        expect(subscriber).to be_a(::Caffeinate::CampaignSubscription)
      end

      it 'is persisted' do
        subscriber = campaign.subscribe!(company)
        expect(subscriber).to be_persisted
      end

      # stupid hack
      it 'raises ActiveRecord::RecordInvalid when invalid' do
        bad_company = OpenStruct.new
        expect do
          campaign.subscribe!(bad_company)
        end.to raise_error
      end
    end
  end

  describe '#subscriber' do
    context 'without args' do
      let(:subscribed_company) { create(:company) }
      let(:unsubscribed_company) { create(:company) }

      before do
        campaign.subscribe!(subscribed_company)
      end

      context 'a subscription is present' do
        it 'returns a CampaignSubscription' do
          lookup = campaign.subscriber(subscribed_company)
          expect(lookup).to be_a(Caffeinate::CampaignSubscription)
        end

        it 'returns a persisted CampaignSubscription' do
          lookup = campaign.subscriber(subscribed_company)
          expect(lookup).to be_persisted
        end

        it 'returns the correct subscriber' do
          lookup = campaign.subscriber(subscribed_company)
          expect(lookup.subscriber).to eq(subscribed_company)
        end
      end

      context 'a subscription is not present' do
        it 'returns nil' do
          lookup = campaign.subscriber(unsubscribed_company)
          expect(lookup).to be_nil
        end
      end
    end
  end

  describe '#subscribes?' do
    context 'without args' do
      let(:subscribed_company) { create(:company) }
      let(:unsubscribed_company) { create(:company) }

      before do
        campaign.subscribe!(subscribed_company)
      end

      it 'returns a CampaignSubscription' do
        expect(campaign).to be_subscribes(subscribed_company)
      end

      it 'returns false if not subscribed' do
        expect(campaign).not_to be_subscribes(unsubscribed_company)
      end
    end
  end

  describe '#unsubscribe' do
    context 'without args' do
      context 'a valid subscription' do
        let(:subscribed_company) { create(:company) }

        before do
          campaign.subscribe!(subscribed_company)
        end

        it 'calls unsubscribe! on the subscribed object' do
          expect do
            campaign.unsubscribe(subscribed_company)
          end.to change(::Caffeinate::CampaignSubscription.unsubscribed, :count).by(1)
        end

        it 'calls updates unsubscribed_reason with the given reason' do
          subscription = campaign.subscriber(subscribed_company)
          campaign.unsubscribe(subscribed_company, reason: 'too much pasta')
          subscription.reload
          expect(subscription.unsubscribe_reason).to eq('too much pasta')
        end
      end
    end
  end
end
